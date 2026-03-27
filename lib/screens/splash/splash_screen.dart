import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // SKIP SPLASH: unused while splash is bypassed

/// Splash / loading screen — Firebase init, auth check, deep-link resolution.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigation is handled by the router redirect based on auth state.
    // SKIP SPLASH: auto-navigation disabled while splash is bypassed.
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (mounted) {
    //     context.go('/home');
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeerColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.sports_bar,
              size: 80,
              color: BeerColors.primaryAmber,
            ),
            const SizedBox(height: 16),
            Text(
              'Beerer',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: BeerColors.primaryAmber,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.splashTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                  ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: BeerColors.primaryAmber,
                backgroundColor: BeerColors.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
