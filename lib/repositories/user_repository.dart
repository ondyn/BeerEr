import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:beerer/models/models.dart';

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
      return AppUser.fromJson({'id': snap.id, ...snap.data()!});
    });
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    final data = user.toJson()..remove('id');
    await _col.doc(user.id).set(data, SetOptions(merge: true));
  }
}
