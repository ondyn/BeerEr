import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Forgot password screen — sends password reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = AppLocalizations.of(context)!.pleaseEnterValidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to send reset email.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/auth/sign-in'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.forgotPasswordTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.forgotPasswordSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeerColors.onSurfaceSecondary,
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            labelText: AppLocalizations.of(context)!.email,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeerColors.error,
                ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _sendReset,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BeerColors.background,
                  ),
                )
              : Text(AppLocalizations.of(context)!.sendResetLink),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: BeerColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.checkYourEmail,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.resetLinkSent(_emailController.text.trim()),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeerColors.onSurfaceSecondary,
              ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/auth/sign-in'),
          child: Text(AppLocalizations.of(context)!.backToSignIn),
        ),
      ],
    );
  }
}
