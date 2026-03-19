import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'joint_account_providers.g.dart';

/// Watches all joint accounts for a session.
@riverpod
Stream<List<JointAccount>> watchSessionAccounts(
  Ref ref,
  String sessionId,
) {
  final repo = ref.watch(jointAccountRepositoryProvider);
  return repo.watchSessionAccounts(sessionId);
}

/// Derives the joint account that [userId] belongs to in [sessionId]
/// from the already-watched session accounts stream.
///
/// Returns `null` when the user is not part of any group.
@riverpod
JointAccount? userAccountInSession(
  Ref ref,
  String sessionId,
  String userId,
) {
  final accountsAsync = ref.watch(watchSessionAccountsProvider(sessionId));
  final accounts = accountsAsync.asData?.value ?? [];
  for (final a in accounts) {
    if (a.memberUserIds.contains(userId)) return a;
  }
  return null;
}
