import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Welcome / onboarding screen for new or logged-out users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
