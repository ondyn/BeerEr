import 'package:beerer/models/models.dart';
import 'package:beerer/utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'joint_account_repository.g.dart';

@riverpod
JointAccountRepository jointAccountRepository(Ref ref) =>
    JointAccountRepository(FirebaseFirestore.instance);

class JointAccountRepository {
  const JointAccountRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('jointAccounts');

  /// Watches all joint accounts for a session.
  Stream<List<JointAccount>> watchSessionAccounts(String sessionId) {
    return _col
        .where('session_id', isEqualTo: sessionId)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => JointAccount.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }

  /// Returns the joint account that [userId] belongs to in [sessionId],
  /// or `null` if the user is not in any group.
  Future<JointAccount?> getAccountForUser(
    String sessionId,
    String userId,
  ) async {
    final qs = await _col
        .where('session_id', isEqualTo: sessionId)
        .where('member_user_ids', arrayContains: userId)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    final d = qs.docs.first;
    return JointAccount.fromJson(firestoreDoc(d.id, d.data()));
  }

  /// Creates a new joint account.
  Future<JointAccount> createAccount(JointAccount account) async {
    final data = account.toJson()..remove('id');
    final ref = await _col.add(data);
    return account.copyWith(id: ref.id);
  }

  /// Adds a member to an existing joint account.
  Future<void> addMember(String accountId, String userId) async {
    await _col.doc(accountId).update({
      'member_user_ids': FieldValue.arrayUnion([userId]),
    });
  }

  /// Removes a member from a joint account.
  Future<void> removeMember(String accountId, String userId) async {
    await _col.doc(accountId).update({
      'member_user_ids': FieldValue.arrayRemove([userId]),
    });
  }

  /// Deletes a joint account.
  Future<void> deleteAccount(String accountId) async {
    await _col.doc(accountId).delete();
  }

  /// Updates the account name.
  Future<void> updateName(String accountId, String name) async {
    await _col.doc(accountId).update({'group_name': name});
  }
}
