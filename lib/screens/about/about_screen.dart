import 'package:beerer/l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.about),
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
              'Beerer',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: BeerColors.primaryAmber,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.version('1.0.0'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.aboutDescription,
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
                      AppLocalizations.of(context)!.enjoyUsingBeerer,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.buyDeveloperBeer,
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
                      label: Text(AppLocalizations.of(context)!.tipViaRevolut),
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
                    AppLocalizations.of(context)!.drinkResponsiblyTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: BeerColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.drinkResponsiblyBody,
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
                    AppLocalizations.of(context)!.addictionAwareness,
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
                    child: Text(AppLocalizations.of(context)!.addictionCenterEU),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Beer tasting guide -----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BeerColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_bar,
                    color: BeerColors.primaryAmber,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.beerTastingQuestion,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://beerweb.cz/o-pivu/degustace-piva',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('beerweb.cz — Degustace piva'),
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
              child: Text(AppLocalizations.of(context)!.privacyPolicy),
            ),
            TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Beerer',
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
                      '\u00A9 2026 Beerer. All rights reserved.',
                );
              },
              child: Text(AppLocalizations.of(context)!.openSourceLicences),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
