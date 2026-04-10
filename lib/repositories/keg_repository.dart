import 'package:beerer/models/models.dart';
import 'package:beerer/utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show listEquals;
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
        .map(
          (qs) => qs.docs
              .map((d) => KegSession.fromJson(firestoreDoc(d.id, d.data())))
              .toList(),
        );
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

  /// Watches done sessions for history (only those the user participates in).
  Stream<List<KegSession>> watchDoneSessions(String uid) {
    return _sessions
        .where('status', isEqualTo: 'done')
        .where('participant_ids', arrayContains: uid)
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
        firestoreDoc(sessionSnap.id, sessionSnap.data()!),
      );

      if (keg.status != KegStatus.active) {
        throw StateError('Cannot pour while keg is ${keg.status.name}.');
      }

      // Allow pouring even if keg counter is at 0 — there may be more
      // beer than originally declared. Billing is based on actual pours,
      // not the keg level, so a negative remaining volume is acceptable.

      final pourRef = _pours.doc();
      final data = pour.toJson()..remove('id');
      tx.set(pourRef, data);
      tx.update(_sessions.doc(pour.sessionId), {
        'volume_remaining_ml': keg.volumeRemainingMl - pour.volumeMl,
        'last_volumes_ml.${pour.userId}': pour.volumeMl,
      });

      return pour.copyWith(id: pourRef.id);
    });
  }

  /// Soft-deletes a pour and restores keg volume atomically.
  Future<void> undoPour(Pour pour) async {
    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
      final keg = KegSession.fromJson(
        firestoreDoc(sessionSnap.id, sessionSnap.data()!),
      );

      tx.update(_pours.doc(pour.id), {'undone': true});
      tx.update(_sessions.doc(pour.sessionId), {
        'volume_remaining_ml': keg.volumeRemainingMl + pour.volumeMl,
      });
    });
  }

  /// Adds a pour during bill review (keg is already done).
  ///
  /// Unlike [addPour], this does NOT check keg status or modify
  /// `volume_remaining_ml` — it only creates the pour document.
  Future<Pour> addPourForReview(Pour pour) async {
    final data = pour.toJson()..remove('id');
    final ref = await _pours.add(data);
    return pour.copyWith(id: ref.id);
  }

  /// Soft-deletes a pour during bill review (keg is already done).
  ///
  /// Unlike [undoPour], this does NOT modify `volume_remaining_ml`.
  Future<void> undoPourForReview(Pour pour) async {
    await _pours.doc(pour.id).update({'undone': true});
  }

  Future<void> updateStatus(String sessionId, KegStatus status) async {
    final data = <String, dynamic>{'status': status.name};
    if (status == KegStatus.done) {
      data['end_time'] = FieldValue.serverTimestamp();
    }
    await _sessions.doc(sessionId).update(data);
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
    String sessionId,
    Map<String, dynamic> data,
  ) async {
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
  ///
  /// Uses [distinct] with deep list equality so that downstream providers
  /// (e.g. `watchUsersProvider(ids)`) keep the same list reference when
  /// participant_ids haven't changed — even if the session document was
  /// updated for unrelated fields like `volume_remaining_ml`.
  Stream<List<String>> watchParticipantIds(String sessionId) {
    return _sessions
        .doc(sessionId)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return <String>[];
          final data = snap.data()!;
          final ids = data['participant_ids'] as List<dynamic>?;
          return ids?.cast<String>() ?? <String>[];
        })
        .distinct(listEquals);
  }

  Stream<List<Pour>> watchPours(String sessionId) {
    return _pours
        .where('session_id', isEqualTo: sessionId)
        .where('undone', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (qs) => qs.docs
              .map((d) => Pour.fromJson(firestoreDoc(d.id, d.data())))
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Manual (guest) users
  // ---------------------------------------------------------------------------

  /// Subcollection reference for manual users within a session.
  CollectionReference<Map<String, dynamic>> _manualUsers(String sessionId) =>
      _sessions.doc(sessionId).collection('manualUsers');

  /// Creates a guest participant in the session.
  Future<ManualUser> addManualUser(String sessionId, String nickname) async {
    final ref = _manualUsers(sessionId).doc();
    final guest = ManualUser(
      id: ref.id,
      sessionId: sessionId,
      nickname: nickname,
    );
    final data = guest.toJson()..remove('id');
    await ref.set(data);
    return guest;
  }

  /// Removes a manual user and rolls back their pours atomically.
  ///
  /// 1. Soft-deletes all active pours by the guest (`undone: true`).
  /// 2. Restores the keg's `volume_remaining_ml` by the total of those pours.
  /// 3. Deletes the manual user document.
  ///
  /// Uses a batched write for atomicity.
  Future<void> removeManualUser(String sessionId, String manualUserId) async {
    // Fetch all active pours for this guest.
    final poursSnap = await _pours
        .where('session_id', isEqualTo: sessionId)
        .where('user_id', isEqualTo: manualUserId)
        .where('undone', isEqualTo: false)
        .get();

    // Calculate total volume to restore.
    double totalVolumeMl = 0;
    for (final doc in poursSnap.docs) {
      final volumeMl = (doc.data()['volume_ml'] as num?)?.toDouble() ?? 0;
      totalVolumeMl += volumeMl;
    }

    final batch = _db.batch();

    // Soft-delete each pour.
    for (final doc in poursSnap.docs) {
      batch.update(doc.reference, {'undone': true});
    }

    // Restore keg volume.
    if (totalVolumeMl > 0) {
      batch.update(_sessions.doc(sessionId), {
        'volume_remaining_ml': FieldValue.increment(totalVolumeMl),
      });
    }

    // Delete the manual user document.
    batch.delete(_manualUsers(sessionId).doc(manualUserId));

    await batch.commit();
  }

  /// Watches all manual users for a session.
  Stream<List<ManualUser>> watchManualUsers(String sessionId) {
    return _manualUsers(sessionId).snapshots().map(
      (qs) => qs.docs
          .map((d) => ManualUser.fromJson(firestoreDoc(d.id, d.data())))
          .toList(),
    );
  }

  /// Merges a manual user into a real user:
  /// 1. Reassigns all pours whose `user_id` matches [manualUserId] to
  ///    [realUserId].
  /// 2. Deletes the manual user document.
  ///
  /// Uses a batched write for atomicity.
  Future<void> mergeManualUser({
    required String sessionId,
    required String manualUserId,
    required String realUserId,
  }) async {
    final poursSnap = await _pours
        .where('session_id', isEqualTo: sessionId)
        .where('user_id', isEqualTo: manualUserId)
        .get();

    final batch = _db.batch();
    for (final doc in poursSnap.docs) {
      batch.update(doc.reference, {
        'user_id': realUserId,
        'poured_by_id': realUserId,
      });
    }
    batch.delete(_manualUsers(sessionId).doc(manualUserId));
    await batch.commit();
  }
}
