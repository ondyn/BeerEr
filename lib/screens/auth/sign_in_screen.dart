import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/locale_provider.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Sign-in screen with email/password and social providers.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  bool _emailNotVerified = false;
  bool _isResending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _emailNotVerified = false;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      var user = credential.user;

      if (user == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.signInFailed;
        });
        return;
      }

      // Reload the user profile so emailVerified reflects the latest
      // server-side state (the cached token may be stale if the user
      // just confirmed their email in a browser).
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user == null || !user.emailVerified) {
        // Block access until email is verified.
        // Sign out immediately so the router doesn't redirect.
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _emailNotVerified = true;
            _error = AppLocalizations.of(context)!.emailNotVerifiedError;
          });
        }
        return;
      }

      // Ensure a Firestore profile exists (may have been wiped or never
      // created — e.g. the DB was cleared while Auth users were kept).
      // Use createMinimalProfile so we don't overwrite weight/age/gender
      // with default values if the profile somehow already exists.
      final userRepo = ref.read(userRepositoryProvider);
      final existingProfile = await userRepo.getUser(user.uid);
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
        );
      }

      // Sync the pre-auth language preference to Firestore so the user
      // keeps the language they selected on the welcome screen.
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

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _mapFirebaseError(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'wrong-password':
        return l10n.wrongPasswordError;
      case 'user-not-found':
        return l10n.userNotFoundError;
      case 'invalid-credential':
        return l10n.invalidCredentialError;
      case 'too-many-requests':
        return l10n.tooManyRequestsError;
      case 'user-disabled':
        return l10n.signInFailed;
      case 'invalid-email':
        return l10n.enterValidEmail;
      case 'account-exists-with-different-credential':
        return l10n.accountExistsWithDifferentCredential;
      default:
        return l10n.signInFailed;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _emailNotVerified = false;
    });

    try {
      debugPrint('[GoogleSignIn] Starting sign-in flow...');
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[GoogleSignIn] User cancelled the flow.');
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context)!.googleSignInCancelled;
            _isLoading = false;
          });
        }
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
        setState(() {
          _error = AppLocalizations.of(context)!.googleSignInFailed;
        });
        return;
      }

      // Ensure a Firestore profile exists.
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

      // Sync pre-auth locale to Firestore.
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

      debugPrint('[GoogleSignIn] Success — navigating');
      if (mounted) {
        if (existingProfile == null) {
          context.go('/auth/complete-profile');
        } else {
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleSignIn] FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (mounted) {
        setState(() {
          _error = _mapFirebaseError(e.code);
        });
      }
    } catch (e, st) {
      debugPrint('[GoogleSignIn] Unexpected error: $e');
      debugPrint('[GoogleSignIn] Stack trace: $st');
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.googleSignInFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      // Sign in again briefly to get the user object for resend.
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.verificationEmailResent;
          _emailNotVerified = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _mapFirebaseError(e.code);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.signInFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.signInToBeerEr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: AppLocalizations.of(context)!.email,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterEmail;
                    }
                    if (!val.contains('@')) {
                      return AppLocalizations.of(context)!.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outlined),
                    labelText: AppLocalizations.of(context)!.password,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscurePassword = !_obscurePassword,
                        );
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/auth/forgot-password'),
                    child: Text(AppLocalizations.of(context)!.forgotPassword),
                  ),
                ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _emailNotVerified
                          ? BeerColors.warning.withValues(alpha: 0.15)
                          : BeerColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _emailNotVerified
                            ? BeerColors.warning.withValues(alpha: 0.3)
                            : BeerColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _emailNotVerified
                                  ? Icons.mark_email_unread_outlined
                                  : Icons.error_outline,
                              color: _emailNotVerified
                                  ? BeerColors.warning
                                  : BeerColors.error,
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
                                      color: _emailNotVerified
                                          ? BeerColors.warning
                                          : BeerColors.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (_emailNotVerified) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed:
                                _isResending ? null : _resendVerificationEmail,
                            icon: _isResending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!
                                  .resendVerificationEmail,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Sign in button
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BeerColors.background,
                          ),
                        )
                      : Text(AppLocalizations.of(context)!.signIn),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context)!.or,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: Text(
                      AppLocalizations.of(context)!.signInWithGoogle),
                ),
                const SizedBox(height: 24),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.noAccount),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: Text(AppLocalizations.of(context)!.registerLink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
