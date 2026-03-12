import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

/// Watches the current user profile.
/// If the stored doc has no email yet, back-fills it from Firebase Auth.
@riverpod
Stream<AppUser?> watchCurrentUser(Ref ref, String userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUser(userId).map((user) {
    if (user != null && user.email.isEmpty) {
      final fbEmail =
          FirebaseAuth.instance.currentUser?.email ?? '';
      if (fbEmail.isNotEmpty) {
        // Back-fill silently; don't await — fire and forget.
        repo.createOrUpdateUser(user.copyWith(email: fbEmail));
        return user.copyWith(email: fbEmail);
      }
    }
    return user;
  });
}

/// Watches multiple users (e.g. participants).
@riverpod
Stream<List<AppUser>> watchUsers(Ref ref, List<String> userIds) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUsers(userIds);
}
