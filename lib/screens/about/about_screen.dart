import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// About screen — logo, version, disclaimers.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.sports_bar,
              size: 80,
              color: BeerColors.primaryAmber,
            ),
            const SizedBox(height: 16),
            Text(
              'BeerEr',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: BeerColors.primaryAmber,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              'BeerEr is a keg beer tracker for parties. '
              'Track every pour, see real-time stats, '
              'and settle costs easily.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            // Responsible drinking notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BeerColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BeerColors.warning),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: BeerColors.warning,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drink Responsibly',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: BeerColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BAC estimates are for informational purposes only '
                    'and should not be used to determine fitness to drive. '
                    'Please drink responsibly.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'BeerEr',
                  applicationVersion: '1.0.0',
                );
              },
              child: const Text('Open-source licences'),
            ),
            TextButton(
              onPressed: () {
                // TODO: open privacy policy URL
              },
              child: const Text('Privacy policy'),
            ),
          ],
        ),
      ),
    );
  }
}
