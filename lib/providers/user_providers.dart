import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

/// Watches the current user profile.
/// If the stored doc has no email yet, back-fills it from Firebase Auth.
/// If no Firestore profile exists at all, auto-creates a minimal one so
/// the user's nickname is never a truncated UID hash.
@riverpod
Stream<AppUser?> watchCurrentUser(Ref ref, String userId) {
  final repo = ref.watch(userRepositoryProvider);
  bool autoCreating = false;
  return repo.watchUser(userId).map((user) {
    if (user == null && !autoCreating) {
      // No profile in Firestore — create a minimal one from Firebase Auth
      // data. Use createMinimalProfile to avoid overwriting fields like
      // weight/age/gender with default values if the doc is later restored.
      autoCreating = true;
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.uid == userId) {
        final fallbackNickname =
            fbUser.displayName?.trim().isNotEmpty == true
                ? fbUser.displayName!.trim()
                : (fbUser.email != null && fbUser.email!.isNotEmpty
                    ? fbUser.email!.split('@').first
                    : 'Beerer user');
        // Fire and forget — the snapshot stream will emit the new doc.
        repo.createMinimalProfile(
          uid: fbUser.uid,
          nickname: fallbackNickname,
          email: fbUser.email ?? '',
        );
      }
      return null;
    }
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
