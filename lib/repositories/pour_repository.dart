import 'package:beerer/models/models.dart';
import 'package:beerer/utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pour_repository.g.dart';

@riverpod
PourRepository pourRepository(Ref ref) =>
    PourRepository(FirebaseFirestore.instance);

class PourRepository {
  const PourRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _pours =>
      _db.collection('pours');

  /// Watches all active (not undone) pours for a session.
  Stream<List<Pour>> watchSessionPours(String sessionId) {
    return _pours
        .where('session_id', isEqualTo: sessionId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => Pour.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }

  /// Watches pours for a specific user within a session.
  Stream<List<Pour>> watchUserPours(String sessionId, String userId) {
    return _pours
        .where('session_id', isEqualTo: sessionId)
        .where('user_id', isEqualTo: userId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => Pour.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }

  /// Gets the most recent pour for a user to remember last volume.
  Future<Pour?> getLastPour(String userId) async {
    final qs = await _pours
        .where('user_id', isEqualTo: userId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    final d = qs.docs.first;
    return Pour.fromJson(firestoreDoc(d.id, d.data()));
  }
}
