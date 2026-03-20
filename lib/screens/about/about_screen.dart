import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
            // App logo
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 96,
              height: 96,
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

            // ----- Tip the developer (same as keg done screen) -----
            Card(
              color: BeerColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '\u{1F37B}', // 🍻
                      style: TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enjoy using BeerEr?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Buy the developer a beer!',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: BeerColors.onSurfaceSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://revolut.me/hnyko'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Tip via Revolut'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ----- Responsible drinking notice -----
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
                    'and should not be used to determine fitness to '
                    'drive. Please drink responsibly.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://responsibledrinking.eu/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('responsibledrinking.eu'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Addiction awareness card -----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BeerColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.health_and_safety,
                    color: BeerColors.onSurfaceSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you are using this app often, consider visiting:',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.addictioncenter.com/'
                        'addiction/addiction-in-the-eu/',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Addiction Center EU'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // ----- Links -----
            TextButton(
              onPressed: () => context.push('/privacy'),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'BeerEr',
                  applicationVersion: '1.0.0',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  applicationLegalese:
                      '\u00A9 2026 BeerEr. All rights reserved.',
                );
              },
              child: const Text('Open-source licences'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
