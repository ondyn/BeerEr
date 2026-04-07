import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/locale_provider.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Welcome / onboarding screen for new or logged-out users.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _signInWithGoogle(
      BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('[GoogleSignIn] Starting sign-in flow (welcome)...');
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[GoogleSignIn] User cancelled the flow.');
        return;
      }

      debugPrint('[GoogleSignIn] Got Google user: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      debugPrint(
        '[GoogleSignIn] Got tokens — '
        'accessToken: ${googleAuth.accessToken != null ? "present" : "null"}, '
        'idToken: ${googleAuth.idToken != null ? "present" : "null"}',
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[GoogleSignIn] Calling signInWithCredential...');
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      debugPrint(
        '[GoogleSignIn] signInWithCredential result — '
        'uid: ${user?.uid}, email: ${user?.email}, '
        'isNewUser: ${userCredential.additionalUserInfo?.isNewUser}',
      );

      if (user == null) {
        debugPrint('[GoogleSignIn] ERROR: user is null after signInWithCredential');
        return;
      }

      // Ensure Firestore profile exists.
      final userRepo = ref.read(userRepositoryProvider);
      final existingProfile = await userRepo.getUser(user.uid);
      debugPrint('[GoogleSignIn] Existing profile: ${existingProfile != null}');
      if (existingProfile == null) {
        final fallbackNickname =
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : (user.email != null && user.email!.isNotEmpty
                    ? user.email!.split('@').first
                    : 'Beerer user');
        await userRepo.createMinimalProfile(
          uid: user.uid,
          nickname: fallbackNickname,
          email: user.email ?? '',
          authProvider: 'google',
        );
        debugPrint('[GoogleSignIn] Created profile for ${user.uid}');
      }

      // Sync pre-auth locale.
      final preAuthLang = ref.read(preAuthLocaleProvider);
      if (preAuthLang != null) {
        final profile = await userRepo.getUser(user.uid);
        if (profile != null) {
          final currentLang =
              profile.preferences['language'] as String? ?? 'en';
          if (currentLang != preAuthLang) {
            final updatedPrefs =
                Map<String, dynamic>.from(profile.preferences)
                  ..['language'] = preAuthLang;
            await userRepo.createOrUpdateUser(
              profile.copyWith(preferences: updatedPrefs),
            );
          }
        }
      }

      debugPrint('[GoogleSignIn] Success — navigating to /home');
      if (context.mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleSignIn] FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = e.code == 'account-exists-with-different-credential'
            ? l10n.accountExistsWithDifferentCredential
            : (e.message ?? l10n.googleSignInFailed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e, st) {
      debugPrint('[GoogleSignIn] Unexpected error: $e');
      debugPrint('[GoogleSignIn] Stack trace: $st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.googleSignInFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BeerColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: constraints.maxHeight > 500 ? 60 : 16),
                    // Language selector
                    const _LanguagePicker(),
                    const SizedBox(height: 16),
                    // Logo
                    SvgPicture.asset(
                      'assets/images/logo_no_bg.svg',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Beerer',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: BeerColors.primaryAmber,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.welcomeTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: BeerColors.onSurfaceSecondary,
                          ),
                    ),
                    SizedBox(
                        height: constraints.maxHeight > 500 ? 60 : 24),
                    // Sign in button
                    FilledButton(
                      onPressed: () => context.go('/auth/sign-in'),
                      child: Text(AppLocalizations.of(context)!.signIn),
                    ),
                    const SizedBox(height: 12),
                    // Register button
                    OutlinedButton(
                      onPressed: () => context.go('/auth/register'),
                      child:
                          Text(AppLocalizations.of(context)!.createAccount),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)!.or,
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _signInWithGoogle(context, ref),
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        AppLocalizations.of(context)!.signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact language picker shown on the welcome screen before sign-in.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  static const _languages = [
    ('en', 'English', '🇬🇧'),
    ('cs', 'Čeština', '🇨🇿'),
    ('de', 'Deutsch', '🇩🇪'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final current = locale.languageCode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.language, size: 18, color: BeerColors.onSurfaceSecondary),
        const SizedBox(width: 4),
        DropdownButton<String>(
          value: _languages.any((l) => l.$1 == current) ? current : 'en',
          underline: const SizedBox.shrink(),
          dropdownColor: BeerColors.surface,
          items: _languages
              .map((l) => DropdownMenuItem(
                    value: l.$1,
                    child: Text(
                      '${l.$3} ${l.$2}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            ref.read(preAuthLocaleProvider.notifier).set(val);
            saveLocalLanguage(val);
          },
        ),
      ],
    );
  }
}
