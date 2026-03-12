import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/pour_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pour_providers.g.dart';

/// Watches all active pours for a session.
@riverpod
Stream<List<Pour>> watchSessionPours(Ref ref, String sessionId) {
  final repo = ref.watch(pourRepositoryProvider);
  return repo.watchSessionPours(sessionId);
}

/// Watches pours for a specific user within a session.
@riverpod
Stream<List<Pour>> watchUserPours(
  Ref ref,
  String sessionId,
  String userId,
) {
  final repo = ref.watch(pourRepositoryProvider);
  return repo.watchUserPours(sessionId, userId);
}
