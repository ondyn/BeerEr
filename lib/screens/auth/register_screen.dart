import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Registration screen with email/password and profile details.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user!;

      // Send verification email.
      try {
        await user.sendEmailVerification();
        debugPrint('[Beerer] Verification email sent to ${user.email}');
      } catch (e) {
        // Log the error but don't block account creation.
        debugPrint('[Beerer] sendEmailVerification failed: $e');
      }

      // Create a minimal profile in Firestore (email + email-provider only).
      // User will complete profile details after email verification during sign-in.
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.createMinimalProfile(
        uid: user.uid,
        nickname: user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        authProvider: 'email',
      );

      // Try to relink a previously deleted (suspended) account with the
      // same email — this reassigns all old pours/sessions to the new UID.
      try {
        final suspended = await userRepo.findSuspendedByEmail(
          user.email ?? '',
        );
        if (suspended != null) {
          await userRepo.relinkSuspendedAccount(
            oldUserId: suspended.id,
            newUserId: user.uid,
            nickname: user.email?.split('@').first ?? 'User',
            email: user.email ?? '',
            weightKg: 0,
            age: 0,
            gender: 'male',
          );
        }
      } catch (_) {
        // Best-effort: don't block registration if relinking fails.
        debugPrint('[Beerer] relinkSuspendedAccount failed (non-critical)');
      }

      if (mounted) {
        // Sign out so the user cannot use the app until email is verified.
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.accountCreatedVerify,
            ),
          ),
        );
        if (!mounted) return;
        context.go('/auth/sign-in');
        return; // Widget will be disposed — skip finally setState.
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'internal-error' ||
            (e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
          _error = AppLocalizations.of(context)!.emailSignInNotConfigured;
        } else {
          _error = e.message ?? AppLocalizations.of(context)!.registrationFailed;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.registrationFailed;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/welcome')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.createAccount,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: AppLocalizations.of(context)!.email,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterEmail;
                    }
                    if (!val.contains('@')) return AppLocalizations.of(context)!.enterValidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outlined),
                    labelText: AppLocalizations.of(context)!.password,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return AppLocalizations.of(context)!.passwordMinLength;
                    }
                    return null;
                  },
                ),
                // Live password length hint
                if (_passwordController.text.isNotEmpty &&
                    _passwordController.text.length < 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: BeerColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.passwordMinLength,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: BeerColors.warning,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Confirm password
                TextFormField(
                  controller: _confirmPwdController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outlined),
                    labelText: AppLocalizations.of(context)!.confirmPassword,
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BeerColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: BeerColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: BeerColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: BeerColors.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Register button
                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BeerColors.background,
                          ),
                        )
                      : Text(AppLocalizations.of(context)!.createAccount),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.alreadyHaveOne),
                    TextButton(
                      onPressed: () => context.go('/auth/sign-in'),
                      child: Text(AppLocalizations.of(context)!.signInLink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
