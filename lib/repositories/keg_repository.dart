import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:beerer/models/models.dart';

part 'keg_repository.g.dart';

@riverpod
KegRepository kegRepository(Ref ref) =>
    KegRepository(FirebaseFirestore.instance);

class KegRepository {
  const KegRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('kegSessions');

  CollectionReference<Map<String, dynamic>> get _pours =>
      _db.collection('pours');

  Stream<KegSession?> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return KegSession.fromJson({'id': snap.id, ...snap.data()!});
    });
  }

  Stream<List<KegSession>> watchActiveSessions() {
    return _sessions
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => KegSession.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  Future<KegSession> createSession(KegSession session) async {
    final data = session.toJson()..remove('id');
    final ref = await _sessions.add(data);
    return session.copyWith(id: ref.id);
  }

  /// Adds a pour and decrements keg volume atomically.
  /// Throws [StateError] if the keg is not active or volume would go negative.
  Future<void> addPour(Pour pour) async {
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
      final keg = KegSession.fromJson({'id': sessionSnap.id, ...sessionSnap.data()!});

      if (keg.status != KegStatus.active) {
        throw StateError('Cannot pour while keg is ${keg.status.name}.');
      }
      if (keg.volumeRemainingMl < pour.volumeMl) {
        throw StateError('Not enough beer left in the keg.');
      }

      final pourRef = _pours.doc();
      final data = pour.toJson()..remove('id');
      tx.set(pourRef, data);
      tx.update(_sessions.doc(pour.sessionId), {
        'volume_remaining_ml': keg.volumeRemainingMl - pour.volumeMl,
      });
    });
  }

  /// Soft-deletes a pour and restores keg volume atomically.
  Future<void> undoPour(Pour pour) async {
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
      final keg = KegSession.fromJson({'id': sessionSnap.id, ...sessionSnap.data()!});

      tx.update(_pours.doc(pour.id), {'undone': true});
      tx.update(_sessions.doc(pour.sessionId), {
        'volume_remaining_ml': keg.volumeRemainingMl + pour.volumeMl,
      });
    });
  }

  Future<void> updateStatus(String sessionId, KegStatus status) async {
    await _sessions.doc(sessionId).update({'status': status.name});
  }

  Stream<List<Pour>> watchPours(String sessionId) {
    return _pours
        .where('session_id', isEqualTo: sessionId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => Pour.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }
}
