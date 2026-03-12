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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              SvgPicture.asset(
                'assets/images/logo_no_bg.svg',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 8),
              Text(
                'BeerEr',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: BeerColors.primaryAmber,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track every pour.\nSettle every tab.\nDrink all the kegs.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
                    ),
              ),
              const Spacer(),
              // Sign in button
              FilledButton(
                onPressed: () => context.go('/auth/sign-in'),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              // Register button
              OutlinedButton(
                onPressed: () => context.go('/auth/register'),
                child: const Text('Create account'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
