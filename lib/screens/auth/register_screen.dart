import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/local_profile.dart';
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
  final _nicknameController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final local = await LocalProfile.instance.load();
    if (!mounted) return;
    if (local.weightKg > 0 && _weightController.text.isEmpty) {
      _weightController.text = local.weightKg.toStringAsFixed(0);
    }
    if (local.age > 0 && _ageController.text.isEmpty) {
      _ageController.text = local.age.toString();
    }
    setState(() => _gender = local.gender);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    _nicknameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
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
      final uid = user.uid;

      // Send verification email.
      try {
        await user.sendEmailVerification();
        debugPrint('[BeerEr] Verification email sent to ${user.email}');
      } catch (e) {
        // Log the error but don't block account creation.
        debugPrint('[BeerEr] sendEmailVerification failed: $e');
      }

      // Create user profile in Firestore
      final userRepo = ref.read(userRepositoryProvider);
      final weight = double.tryParse(_weightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;
      await userRepo.createOrUpdateUser(AppUser(
        id: uid,
        nickname: _nicknameController.text.trim(),
        email: user.email ?? '',
        weightKg: weight,
        age: age,
        gender: _gender,
        authProvider: 'email',
      ));
      // Persist weight/age/gender locally.
      await LocalProfile.instance.save(
        weightKg: weight,
        age: age,
        gender: _gender,
      );

      if (mounted) {
        // Sign out so the user cannot use the app until email is verified.
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Check your email to verify before signing in.',
            ),
          ),
        );
        context.go('/auth/sign-in');
        return; // Widget will be disposed — skip finally setState.
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'internal-error' ||
            (e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
          _error =
              'Email sign-in is not configured. '
              'Please contact the app admin.';
        } else {
          _error = e.message ?? 'Registration failed. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Registration failed. Please try again.';
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    labelText: 'Email',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outlined),
                    labelText: 'Password',
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Confirm password
                TextFormField(
                  controller: _confirmPwdController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outlined),
                    labelText: 'Confirm password',
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Profile section divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Profile details',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // Nickname
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sports_bar),
                    labelText: 'Nickname',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please choose a nickname';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Weight & Age row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                          labelText: 'Weight (kg)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.cake_outlined),
                          labelText: 'Age',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Gender
                Text(
                  'Gender:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'male',
                      label: Text('Male'),
                      icon: Icon(Icons.male),
                    ),
                    ButtonSegment(
                      value: 'female',
                      label: Text('Female'),
                      icon: Icon(Icons.female),
                    ),
                  ],
                  selected: {_gender},
                  onSelectionChanged: (val) {
                    setState(() => _gender = val.first);
                  },
                ),
                const SizedBox(height: 12),
                // Privacy note
                Text(
                  'ℹ Weight & age are used only for BAC estimation on your device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BeerColors.error,
                        ),
                  ),
                  const SizedBox(height: 8),
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
                      : const Text('Create account'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have one? '),
                    TextButton(
                      onPressed: () => context.go('/auth/sign-in'),
                      child: const Text('Sign in ›'),
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
