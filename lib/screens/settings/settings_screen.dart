import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/local_profile.dart';
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
  bool? _notifyPourForMe;
  bool? _notifyKegNearlyEmpty;
  bool? _notifyKegDone;
  bool? _notifyBacZero;
  bool? _notifySlowdown;

  // Local mirrors for display preferences — seeded from Firestore on first
  // data emission and written back on every change.
  VolumeUnit? _volumeUnit;
  DecimalSeparator? _decimalSeparator;
  String? _language;

  /// Persists a single key/value pair into the user's Firestore preferences
  /// map via a targeted merge write (no read required).
  Future<void> _savePreference(String key, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await ref.read(userRepositoryProvider).updatePreferences(
      userId: uid,
      preferences: {key: value},
    );
  }

  /// Persists the updated [allowPourForMe] value into the user's Firestore
  /// preferences map.
  Future<void> _saveAllowPourForMe(bool value) async {
    setState(() => _allowPourForMe = value);
    await _savePreference('allow_pour_for_me', value);
  }

  void _setVolumeUnit(VolumeUnit unit) {
    setState(() => _volumeUnit = unit);
    _savePreference('volume_unit', unit.key);
  }

  void _setDecimalSeparator(DecimalSeparator sep) {
    setState(() => _decimalSeparator = sep);
    _savePreference('decimal_separator', sep.key);
  }

  void _setLanguage(String langCode) {
    setState(() => _language = langCode);
    _savePreference('language', langCode);
    // Also persist locally so the welcome screen uses the right locale after
    // sign-out and on next cold start.
    saveLocalLanguage(langCode);
  }

  String _volumeUnitLabel(BuildContext context, VolumeUnit unit) {
    final l10n = AppLocalizations.of(context)!;
    return switch (unit) {
      VolumeUnit.litres => l10n.volumeUnitLitres,
      VolumeUnit.pints => l10n.volumeUnitPints,
      VolumeUnit.usFlOz => l10n.volumeUnitUsFlOz,
    };
  }

  /// Shows a confirmation dialog, then calls the `deleteUserAccount` Cloud
  /// Function. On success shows a success message and navigates to welcome.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Watch the live Firestore user document.
    final userAsync = ref.watch(watchCurrentUserProvider(uid));

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
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BeerColors.primaryAmber),
        ),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.error(e.toString()))),
        data: (appUser) {
          // On the first data emission, seed the local state from Firestore.
          final firestoreAllowPourForMe = appUser?.allowPourForMe ?? true;
          final effectiveAllowPourForMe =
              _allowPourForMe ?? firestoreAllowPourForMe;

          // Seed notification preferences from Firestore.
          final firestoreNotifyPourForMe =
              appUser?.preferences['notify_pour_for_me'] as bool? ?? true;
          final firestoreNotifyKegNearlyEmpty =
              appUser?.preferences['notify_keg_nearly_empty'] as bool? ??
                  true;
          final firestoreNotifyKegDone =
              appUser?.preferences['notify_keg_done'] as bool? ?? true;
          final firestoreNotifyBacZero =
              appUser?.preferences['notify_bac_zero'] as bool? ?? true;
          final firestoreNotifySlowdown =
              appUser?.preferences['notify_slowdown'] as bool? ?? true;

          final effectiveNotifyPourForMe =
              _notifyPourForMe ?? firestoreNotifyPourForMe;
          final effectiveNotifyKegNearlyEmpty =
              _notifyKegNearlyEmpty ?? firestoreNotifyKegNearlyEmpty;
          final effectiveNotifyKegDone =
              _notifyKegDone ?? firestoreNotifyKegDone;
          final effectiveNotifyBacZero =
              _notifyBacZero ?? firestoreNotifyBacZero;
          final effectiveNotifySlowdown =
              _notifySlowdown ?? firestoreNotifySlowdown;

          // Seed display preferences from Firestore on first emission.
          final prefs = appUser != null
              ? FormatPreferences.fromMap(appUser.preferences)
              : const FormatPreferences();
          final effectiveVolumeUnit = _volumeUnit ?? prefs.volumeUnit;
          final effectiveDecimalSep =
              _decimalSeparator ?? prefs.decimalSeparator;
          final effectiveLanguage =
              _language ?? (appUser?.preferences['language'] as String? ?? 'en');

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              // Notifications
              _SectionHeader(title: AppLocalizations.of(context)!.notifications),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.allowPourForMe),
                subtitle: Text(
                  AppLocalizations.of(context)!.allowPourForMeSubtitle,
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
                title: Text(AppLocalizations.of(context)!.notifyPourForMe),
                subtitle: Text(
                  AppLocalizations.of(context)!.notifyPourForMeSubtitle,
                ),
                value: effectiveNotifyPourForMe,
                onChanged: (val) {
                  setState(() => _notifyPourForMe = val);
                  _savePreference('notify_pour_for_me', val);
                },
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.kegNearlyEmpty),
                value: effectiveNotifyKegNearlyEmpty,
                onChanged: (val) {
                  setState(() => _notifyKegNearlyEmpty = val);
                  _savePreference('notify_keg_nearly_empty', val);
                },
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.kegDone),
                value: effectiveNotifyKegDone,
                onChanged: (val) {
                  setState(() => _notifyKegDone = val);
                  _savePreference('notify_keg_done', val);
                },
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.readyToDrive),
                subtitle: Text(
                  AppLocalizations.of(context)!.readyToDriveSubtitle,
                ),
                value: effectiveNotifyBacZero,
                onChanged: (val) {
                  setState(() => _notifyBacZero = val);
                  _savePreference('notify_bac_zero', val);
                },
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.slowdownReminder),
                subtitle: Text(
                  AppLocalizations.of(context)!.slowdownReminderSubtitle,
                ),
                value: effectiveNotifySlowdown,
                onChanged: (val) {
                  setState(() => _notifySlowdown = val);
                  _savePreference('notify_slowdown', val);
                },
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Display
              _SectionHeader(title: AppLocalizations.of(context)!.display),
              const SizedBox(height: 8),
              ListTile(
                title: Text(AppLocalizations.of(context)!.volumeUnits),
                trailing: DropdownButton<VolumeUnit>(
                  value: effectiveVolumeUnit,
                  items: VolumeUnit.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              _volumeUnitLabel(context, u),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _setVolumeUnit(val);
                  },
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                title: Text(AppLocalizations.of(context)!.decimalSeparator),
                trailing: DropdownButton<DecimalSeparator>(
                  value: effectiveDecimalSep,
                  items: DecimalSeparator.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == DecimalSeparator.dot
                                  ? AppLocalizations.of(context)!.dotSeparator
                                  : AppLocalizations.of(context)!.commaSeparator,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _setDecimalSeparator(val);
                  },
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                title: Text(AppLocalizations.of(context)!.language),
                trailing: DropdownButton<String>(
                  value: effectiveLanguage,
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'cs',
                      child: Text('Čeština'),
                    ),
                    DropdownMenuItem(
                      value: 'de',
                      child: Text('Deutsch'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) _setLanguage(val);
                  },
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Account
              _SectionHeader(title: AppLocalizations.of(context)!.account),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: Text(AppLocalizations.of(context)!.changePassword),
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
                title: Text(AppLocalizations.of(context)!.signOut),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  await LocalProfile.instance.clear();
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
                title: Text(
                  AppLocalizations.of(context)!.deleteAccount,
                  style: const TextStyle(color: BeerColors.error),
                ),
                tileColor: BeerColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _confirmDeleteAccount(context),
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
