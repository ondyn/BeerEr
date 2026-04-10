import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/local_profile.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:beerer/widgets/avatar_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.profile)),
        body: Center(child: Text(AppLocalizations.of(context)!.notSignedIn)),
      );
    }

    final userAsync =
        ref.watch(watchCurrentUserProvider(firebaseUser.uid));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(AppLocalizations.of(context)!.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                _showEditSheet(context, ref, firebaseUser.uid),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            // Auto-create a minimal profile if missing, then show loader.
            final repo = ref.read(userRepositoryProvider);
            Future.microtask(() async {
              final fbUser = FirebaseAuth.instance.currentUser;
              if (fbUser == null) return;
              final fallbackNickname =
                  fbUser.displayName?.trim().isNotEmpty == true
                      ? fbUser.displayName!.trim()
                      : (fbUser.email != null && fbUser.email!.isNotEmpty
                          ? fbUser.email!.split('@').first
                          : 'Beerer user');
              await repo.createOrUpdateUser(
                AppUser(
                  id: fbUser.uid,
                  nickname: fallbackNickname,
                  email: fbUser.email ?? '',
                ),
              );
            });
            return const Center(
              child: CircularProgressIndicator(
                color: BeerColors.primaryAmber,
              ),
            );
          }
          return _buildProfile(context, ref, user, firebaseUser);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.error(e.toString()))),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    User firebaseUser,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          // Avatar — tap to change
          GestureDetector(
            onTap: () async {
              final picked = await showAvatarPicker(
                context,
                currentCodePoint: user.avatarIcon,
              );
              if (picked == null) return; // dismissed
              final repo = ref.read(userRepositoryProvider);
              final newIcon = picked == -1 ? null : picked;
              await repo.createOrUpdateUser(
                user.copyWith(avatarIcon: newIcon),
              );
            },
            child: Stack(
              children: [
                AvatarCircle(
                  displayName: user.displayName,
                  avatarIcon: user.avatarIcon,
                  radius: 50,
                  isHighlighted: true,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: BeerColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nickname,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            firebaseUser.email ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          // Personal info section
          _SectionHeader(title: AppLocalizations.of(context)!.personalInfo),
          const SizedBox(height: 8),
          _InfoRow(label: AppLocalizations.of(context)!.weight, value: '${user.weightKg} kg'),
          _InfoRow(label: AppLocalizations.of(context)!.age, value: '${user.age}'),
          _InfoRow(
            label: AppLocalizations.of(context)!.gender,
            value: user.gender == 'male' ? AppLocalizations.of(context)!.male : AppLocalizations.of(context)!.female,
          ),
          const SizedBox(height: 24),
          // Privacy settings
          _SectionHeader(title: AppLocalizations.of(context)!.privacySettings),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.showStatsToOthers),
            value: user.preferences['show_stats'] as bool? ?? true,
            onChanged: (val) async {
              final repo = ref.read(userRepositoryProvider);
              final updatedPrefs =
                  Map<String, dynamic>.from(user.preferences)
                    ..['show_stats'] = val;
              await repo.createOrUpdateUser(
                user.copyWith(preferences: updatedPrefs),
              );
            },
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.showBacEstimate),
            subtitle: user.weightKg <= 0
                ? Text(
                    AppLocalizations.of(context)!.setWeightForBac,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BeerColors.error,
                        ),
                  )
                : null,
            value: user.preferences['show_bac'] as bool? ?? false,
            onChanged: (val) async {
              final repo = ref.read(userRepositoryProvider);
              final updatedPrefs =
                  Map<String, dynamic>.from(user.preferences)
                    ..['show_bac'] = val;
              await repo.createOrUpdateUser(
                user.copyWith(preferences: updatedPrefs),
              );
            },
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.showPersonalInfoToOthers),
            value: user.preferences['show_personal_info'] as bool? ?? true,
            onChanged: (val) async {
              final repo = ref.read(userRepositoryProvider);
              final updatedPrefs =
                  Map<String, dynamic>.from(user.preferences)
                    ..['show_personal_info'] = val;
              await repo.createOrUpdateUser(
                user.copyWith(preferences: updatedPrefs),
              );
            },
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          // Session history
          const _SectionHeader(title: 'Session History'),
          const SizedBox(height: 8),
          ListTile(
            title: Text(AppLocalizations.of(context)!.viewHistory),
            trailing: const Icon(Icons.chevron_right),
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => context.go('/sessions/history'),
          ),
          const SizedBox(height: 32),
          // Delete account
          TextButton(
            onPressed: () => _confirmDeleteAccount(context, ref),
            child: Text(
              AppLocalizations.of(context)!.deleteAccount,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeerColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    // Prefill with current user data.
    final currentUser = ref.read(watchCurrentUserProvider(userId)).asData?.value;
    final nicknameCtrl = TextEditingController(
      text: currentUser?.nickname ?? '',
    );
    final weightCtrl = TextEditingController(
      text: currentUser != null && currentUser.weightKg > 0
          ? currentUser.weightKg.toString()
          : '',
    );
    final ageCtrl = TextEditingController(
      text: currentUser != null && currentUser.age > 0
          ? currentUser.age.toString()
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 24 +
              MediaQuery.viewInsetsOf(ctx).bottom +
              MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BeerColors.onSurfaceSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(ctx)!.editProfile,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.nickname),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: AppLocalizations.of(ctx)!.weightKg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: AppLocalizations.of(ctx)!.age),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(ctx)!.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final userRepo = ref.read(userRepositoryProvider);
                      final existing = ref.read(
                        watchCurrentUserProvider(userId),
                      ).asData?.value;
                      final weight =
                          double.tryParse(weightCtrl.text) ?? 0;
                      final age = int.tryParse(ageCtrl.text) ?? 0;
                      final gender = existing?.gender ?? 'male';
                      await userRepo.createOrUpdateUser(AppUser(
                        id: userId,
                        nickname: nicknameCtrl.text.trim(),
                        email: existing?.email ?? '',
                        weightKg: weight,
                        age: age,
                        gender: gender,
                        authProvider: existing?.authProvider ?? 'email',
                        preferences: existing?.preferences ?? {},
                      ));
                      // Persist locally for next login.
                      await LocalProfile.instance.save(
                        weightKg: weight,
                        age: age,
                        gender: gender,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(AppLocalizations.of(ctx)!.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog, then calls the `deleteUserAccount` Cloud
  /// Function. On success shows a success message and navigates to welcome.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: BeerColors.error),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Soft-delete the Firestore profile (keeps email for relink).
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.softDeleteUser(user.uid);

      // 2. Delete the Firebase Auth account.
      await user.delete();

      // 3. Clear local data.
      await LocalProfile.instance.clear();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.deleteAccountSuccess),
            duration: const Duration(seconds: 4),
          ),
        );

      context.go('/welcome');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.deleteAccountFailed(e.message ?? e.code)),
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.deleteAccountFailed(e.toString())),
          ),
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
