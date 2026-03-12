import 'package:beerer/models/models.dart';
import 'package:beerer/utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Stream<KegSession?> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return KegSession.fromJson(firestoreDoc(snap.id, snap.data()!));
    });
  }

  Stream<List<KegSession>> watchActiveSessions() {
    return _sessions
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => KegSession.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }

  /// Watches all sessions where [userId] participates (including creator).
  Stream<List<KegSession>> watchAllSessions(String userId) {
    return _sessions
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .map((qs) {
      final sessions = qs.docs
          .map((d) => KegSession.fromJson(firestoreDoc(d.id, d.data())))
          .toList();
      // Sort client-side to avoid needing a composite index.
      sessions.sort((a, b) {
        final aTime = a.startTime ?? DateTime(2000);
        final bTime = b.startTime ?? DateTime(2000);
        return bTime.compareTo(aTime); // descending
      });
      return sessions;
    });
  }

  /// Watches done sessions for history.
  Stream<List<KegSession>> watchDoneSessions() {
    return _sessions
        .where('status', isEqualTo: 'done')
        .snapshots()
        .map((qs) {
      final sessions = qs.docs
          .map((d) => KegSession.fromJson(firestoreDoc(d.id, d.data())))
          .toList();
      sessions.sort((a, b) {
        final aTime = a.startTime ?? DateTime(2000);
        final bTime = b.startTime ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return sessions;
    });
  }

  /// Gets a session by ID (one-time read).
  Future<KegSession?> getSession(String sessionId) async {
    final snap = await _sessions.doc(sessionId).get();
    if (!snap.exists) return null;
    return KegSession.fromJson(firestoreDoc(snap.id, snap.data()!));
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<KegSession> createSession(KegSession session) async {
    final data = session.toJson()..remove('id');
    final ref = await _sessions.add(data);
    final sessionId = ref.id;
    // Store the deep-link join URL now that we know the session ID.
    final joinLink = 'beerer://join/$sessionId';
    await ref.update({'join_link': joinLink});
    return session.copyWith(id: sessionId, joinLink: joinLink);
  }

  /// Adds a pour and decrements keg volume atomically.
  Future<Pour> addPour(Pour pour) async {
    return await _db.runTransaction<Pour>((tx) async {
      final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
      final keg = KegSession.fromJson(
          firestoreDoc(sessionSnap.id, sessionSnap.data()!));

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

      return pour.copyWith(id: pourRef.id);
    });
  }

  /// Soft-deletes a pour and restores keg volume atomically.
  Future<void> undoPour(Pour pour) async {
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
      final keg = KegSession.fromJson(
          firestoreDoc(sessionSnap.id, sessionSnap.data()!));

      tx.update(_pours.doc(pour.id), {'undone': true});
      tx.update(_sessions.doc(pour.sessionId), {
        'volume_remaining_ml': keg.volumeRemainingMl + pour.volumeMl,
      });
    });
  }

  Future<void> updateStatus(String sessionId, KegStatus status) async {
    await _sessions.doc(sessionId).update({'status': status.name});
  }

  /// Taps the keg — sets start_time and status to active.
  Future<void> tapKeg(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': KegStatus.active.name,
      'start_time': FieldValue.serverTimestamp(),
    });
  }

  /// Updates session details (used by creator).
  Future<void> updateSession(
      String sessionId, Map<String, dynamic> data) async {
    await _sessions.doc(sessionId).update(data);
  }

  /// Deletes a session (only if not yet tapped).
  Future<void> deleteSession(String sessionId) async {
    await _sessions.doc(sessionId).delete();
  }

  /// Adds a participant to the session.
  Future<void> addParticipant(String sessionId, String userId) async {
    await _sessions.doc(sessionId).update({
      'participant_ids': FieldValue.arrayUnion([userId]),
    });
  }

  /// Watches the list of participant IDs.
  Stream<List<String>> watchParticipantIds(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data()!;
      final ids = data['participant_ids'] as List<dynamic>?;
      return ids?.cast<String>() ?? <String>[];
    });
  }

  Stream<List<Pour>> watchPours(String sessionId) {
    return _pours
        .where('session_id', isEqualTo: sessionId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => Pour.fromJson(firestoreDoc(d.id, d.data())))
            .toList());
  }
}
