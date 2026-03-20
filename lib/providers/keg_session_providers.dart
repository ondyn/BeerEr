import 'dart:async';

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:beerer/providers/auth_provider.dart';

part 'keg_session_providers.g.dart';

/// Watches a single keg session by ID.
@riverpod
Stream<KegSession?> watchSession(Ref ref, String sessionId) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchSession(sessionId);
}

/// Watches all active sessions.
@riverpod
Stream<List<KegSession>> watchActiveSessions(Ref ref) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchActiveSessions();
}

/// Watches all sessions where the current user participates or is creator.
@riverpod
Stream<List<KegSession>> watchAllSessions(Ref ref) {
  final repo = ref.watch(kegRepositoryProvider);
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;

  if (user == null) {
    // While auth is loading or user is signed out, expose an empty stream.
    return const Stream<List<KegSession>>.empty();
  }

  return repo.watchAllSessions(user.uid);
}

/// Watches done sessions for history.
@riverpod
Stream<List<KegSession>> watchDoneSessions(Ref ref) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchDoneSessions();
}

/// Watches participant IDs for a session.
@riverpod
Stream<List<String>> watchParticipantIds(Ref ref, String sessionId) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchParticipantIds(sessionId);
}

/// Watches manual (guest) users for a session.
@riverpod
Stream<List<ManualUser>> watchManualUsers(Ref ref, String sessionId) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchManualUsers(sessionId);
}
