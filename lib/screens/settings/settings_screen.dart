import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local mirror of toggle state — initialised once from Firestore.
  bool? _allowPourForMe;
  bool _notifyKegNearlyEmpty = true;
  bool _notifyKegDone = true;
  String _volumeUnit = 'Litres';

  /// Persists the updated [allowPourForMe] value into the user's Firestore
  /// preferences map.
  Future<void> _saveAllowPourForMe(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _allowPourForMe = value);
    final repo = ref.read(userRepositoryProvider);
    final user = await repo.getUser(uid);
    if (user == null) return;
    final updatedPrefs =
        Map<String, dynamic>.from(user.preferences)
          ..['allow_pour_for_me'] = value;
    await repo.createOrUpdateUser(user.copyWith(preferences: updatedPrefs));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Watch the live Firestore user document.
    final userAsync = ref.watch(watchCurrentUserProvider(uid));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('Settings'),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BeerColors.primaryAmber),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appUser) {
          // On the first data emission, seed the local state from Firestore.
          final firestoreAllowPourForMe = appUser?.allowPourForMe ?? true;
          final effectiveAllowPourForMe =
              _allowPourForMe ?? firestoreAllowPourForMe;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Notifications
              const _SectionHeader(title: 'Notifications'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Allow others to pour for me'),
                subtitle: const Text(
                  'Other participants can log a pour on your behalf',
                ),
                value: effectiveAllowPourForMe,
                onChanged: _saveAllowPourForMe,
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('Keg nearly empty'),
                value: _notifyKegNearlyEmpty,
                onChanged: (val) =>
                    setState(() => _notifyKegNearlyEmpty = val),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('Keg done'),
                value: _notifyKegDone,
                onChanged: (val) =>
                    setState(() => _notifyKegDone = val),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Display
              const _SectionHeader(title: 'Display'),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Volume units'),
                trailing: DropdownButton<String>(
                  value: _volumeUnit,
                  items: ['Litres', 'Millilitres', 'Pints']
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _volumeUnit = val);
                  },
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Account
              const _SectionHeader(title: 'Account'),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Change password'),
                trailing: const Icon(Icons.chevron_right),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  // TODO: change password flow
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/welcome');
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: BeerColors.error,
                ),
                title: const Text(
                  'Delete account',
                  style: TextStyle(color: BeerColors.error),
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  // TODO: confirm + delete account
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BeerColors.onSurfaceSecondary,
            ),
      ),
    );
  }
}
