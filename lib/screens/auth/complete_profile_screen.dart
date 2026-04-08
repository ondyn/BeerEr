import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/local_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen shown after Google sign-in when the user profile is incomplete
/// (missing weight, age, gender). Lets the user fill in profile details
/// before proceeding to the home screen.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    final profile = await userRepo.getUser(user.uid);
    if (!mounted) return;

    if (profile != null && _nicknameController.text.isEmpty) {
      _nicknameController.text = profile.nickname;
    }

    // Pre-fill from local profile if available.
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
    _nicknameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRepo = ref.read(userRepositoryProvider);
      final existing = await userRepo.getUser(user.uid);
      final weight = double.tryParse(_weightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;

      final updated = (existing ?? AppUser(
        id: user.uid,
        nickname: _nicknameController.text.trim(),
        email: user.email ?? '',
        authProvider: 'google',
      )).copyWith(
        nickname: _nicknameController.text.trim(),
        weightKg: weight,
        age: age,
        gender: _gender,
      );

      await userRepo.createOrUpdateUser(updated);

      // Persist locally for BAC calculator.
      await LocalProfile.instance.save(
        weightKg: weight,
        age: age,
        gender: _gender,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.completeProfile),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(l10n.skip),
          ),
        ],
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
                  l10n.completeProfileSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                // Nickname
                TextFormField(
                  controller: _nicknameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    labelText: l10n.nickname,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.pleaseEnterNickname;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Weight
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    labelText: l10n.weightKg,
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 16),
                // Age
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.cake_outlined),
                    labelText: l10n.age,
                  ),
                ),
                const SizedBox(height: 16),
                // Gender
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.wc_outlined),
                    labelText: l10n.gender,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(l10n.male),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(l10n.female),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BeerColors.onSurface,
                          ),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
