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
