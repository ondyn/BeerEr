import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
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
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final userAsync =
        ref.watch(watchCurrentUserProvider(firebaseUser.uid));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('My Profile'),
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
                          : 'BeerEr user');
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
          return _buildProfile(context, user, firebaseUser);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    AppUser user,
    User firebaseUser,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: BeerColors.primaryAmber,
            child: Text(
              user.nickname.isNotEmpty
                  ? user.nickname[0].toUpperCase()
                  : '?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: BeerColors.background,
                  ),
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
          // Stats section
          const _SectionHeader(title: 'Statistics'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Weight', value: '${user.weightKg} kg'),
          _InfoRow(label: 'Age', value: '${user.age}'),
          _InfoRow(
            label: 'Gender',
            value: user.gender == 'male' ? 'Male' : 'Female',
          ),
          const SizedBox(height: 24),
          // Privacy settings
          const _SectionHeader(title: 'Privacy settings'),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show stats to others'),
            value: user.preferences['show_stats'] as bool? ?? true,
            onChanged: (_) {
              // TODO: update preferences
            },
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show BAC estimate'),
            value: user.preferences['show_bac'] as bool? ?? false,
            onChanged: (_) {
              // TODO: update preferences
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
            title: const Text('View history'),
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
            onPressed: () {
              // TODO: confirm + delete account
            },
            child: Text(
              'Delete account',
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
    final nicknameCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final ageCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
              'Edit Profile',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameCtrl,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      final userRepo = ref.read(userRepositoryProvider);
                      await userRepo.createOrUpdateUser(AppUser(
                        id: userId,
                        nickname: nicknameCtrl.text.trim(),
                        weightKg:
                            double.tryParse(weightCtrl.text) ?? 0,
                        age: int.tryParse(ageCtrl.text) ?? 0,
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
