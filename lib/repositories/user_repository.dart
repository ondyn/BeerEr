import 'package:beerer/models/models.dart';
import 'package:beerer/utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) =>
    UserRepository(FirebaseFirestore.instance);

class UserRepository {
  const UserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Stream<AppUser?> watchUser(String userId) {
    return _col.doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromJson(firestoreDoc(snap.id, snap.data()!));
    });
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    final data = user.toJson()..remove('id');
    await _col.doc(user.id).set(data, SetOptions(merge: true));
  }

  /// Creates a minimal profile with only nickname and email.
  /// Used as a fallback when auto-creating profiles to avoid overwriting
  /// existing fields (weight, age, gender) with default values.
  Future<void> createMinimalProfile({
    required String uid,
    required String nickname,
    required String email,
  }) async {
    await _col.doc(uid).set(
      {
        'nickname': nickname,
        'email': email,
      },
      SetOptions(merge: true),
    );
  }

  /// Updates only the preferences map for a user, merging with existing values.
  Future<void> updatePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    await _col.doc(userId).set(
      {
        'preferences': preferences,
      },
      SetOptions(merge: true),
    );
  }

  /// Reads a user once.
  Future<AppUser?> getUser(String userId) async {
    final snap = await _col.doc(userId).get();
    if (!snap.exists) return null;
    return AppUser.fromJson(firestoreDoc(snap.id, snap.data()!));
  }

  /// Watches multiple users (for participant lists).
  Stream<List<AppUser>> watchUsers(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value([]);
    return _col
        .where(FieldPath.documentId, whereIn: userIds.take(10).toList())
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => AppUser.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }

  /// Deletes a user document.
  Future<void> deleteUser(String userId) async {
    await _col.doc(userId).delete();
  }

  /// Soft-deletes a user: clears personal data but keeps the record with
  /// email so pours/sessions remain consistent for other participants.
  Future<void> softDeleteUser(String userId) async {
    await _col.doc(userId).update({
      'nickname': 'Deleted User',
      'weight_kg': 0,
      'age': 0,
      'gender': 'male',
      'auth_provider': 'email',
      'preferences': <String, dynamic>{},
      'avatar_icon': FieldValue.delete(),
      'suspended': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Finds a suspended account by email (for relinking on re-registration).
  Future<AppUser?> findSuspendedByEmail(String email) async {
    final qs = await _col
        .where('email', isEqualTo: email)
        .where('suspended', isEqualTo: true)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    final d = qs.docs.first;
    return AppUser.fromJson(firestoreDoc(d.id, d.data()));
  }

  /// Reactivates a suspended account with new user data and links it to a
  /// new Firebase Auth UID. Copies the document to the new UID and deletes
  /// the old one.
  Future<void> relinkSuspendedAccount({
    required String oldUserId,
    required String newUserId,
    required String nickname,
    required String email,
    required double weightKg,
    required int age,
    required String gender,
  }) async {
    final batch = _db.batch();
    // Create new user doc under the new UID
    batch.set(_col.doc(newUserId), {
      'nickname': nickname,
      'email': email,
      'weight_kg': weightKg,
      'age': age,
      'gender': gender,
      'auth_provider': 'email',
      'preferences': <String, dynamic>{},
      'suspended': false,
      'deleted_at': FieldValue.delete(),
    });
    // Delete the old suspended doc
    batch.delete(_col.doc(oldUserId));
    await batch.commit();

    // Reassign all pours from old UID to new UID
    final poursCol = _db.collection('pours');
    final userPours = await poursCol
        .where('user_id', isEqualTo: oldUserId)
        .get();
    for (final doc in userPours.docs) {
      await doc.reference.update({'user_id': newUserId});
    }
    final pouredByPours = await poursCol
        .where('poured_by_id', isEqualTo: oldUserId)
        .get();
    for (final doc in pouredByPours.docs) {
      await doc.reference.update({'poured_by_id': newUserId});
    }

    // Update participant_ids in all sessions
    final sessionsCol = _db.collection('kegSessions');
    final sessions = await sessionsCol
        .where('participant_ids', arrayContains: oldUserId)
        .get();
    for (final doc in sessions.docs) {
      await doc.reference.update({
        'participant_ids': FieldValue.arrayRemove([oldUserId]),
      });
      await doc.reference.update({
        'participant_ids': FieldValue.arrayUnion([newUserId]),
      });
    }

    // Update creator_id in sessions created by the old user
    final createdSessions = await sessionsCol
        .where('creator_id', isEqualTo: oldUserId)
        .get();
    for (final doc in createdSessions.docs) {
      await doc.reference.update({'creator_id': newUserId});
    }

    // Update joint accounts
    final accountsCol = _db.collection('jointAccounts');
    final memberAccounts = await accountsCol
        .where('member_user_ids', arrayContains: oldUserId)
        .get();
    for (final doc in memberAccounts.docs) {
      await doc.reference.update({
        'member_user_ids': FieldValue.arrayRemove([oldUserId]),
      });
      await doc.reference.update({
        'member_user_ids': FieldValue.arrayUnion([newUserId]),
      });
    }
    final creatorAccounts = await accountsCol
        .where('creator_id', isEqualTo: oldUserId)
        .get();
    for (final doc in creatorAccounts.docs) {
      await doc.reference.update({'creator_id': newUserId});
    }
  }
}
