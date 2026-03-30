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
}
