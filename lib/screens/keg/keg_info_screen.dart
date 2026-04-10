import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/screens/keg/fullscreen_chart_screen.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:beerer/widgets/keg_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying detailed keg and beer information.
class KegInfoScreen extends ConsumerWidget {
  const KegInfoScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(watchSessionProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(AppLocalizations.of(context)!.sessionNotFound),
            ),
          );
        }
        return _KegInfoBody(session: session);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: BeerColors.primaryAmber),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorWithMessage(e.toString()),
          ),
        ),
      ),
    );
  }
}

class _KegInfoBody extends ConsumerWidget {
  const _KegInfoBody({required this.session});

  final KegSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref
        .watch(formatPreferencesProvider)
        .withCurrency(session.currency);
    final poursAsync = ref.watch(watchSessionPoursProvider(session.id));
    final pours = poursAsync.asData?.value ?? [];

    // Computed stats
    final totalPouredMl = StatsCalculator.totalPouredMl(pours);
    final volumeRemainingMl = session.volumeRemainingMl;
    final alcoholConsumedMl = StatsCalculator.pureAlcoholMl(
      pours,
      session.alcoholPercent,
    );
    final alcoholRemainingMl = StatsCalculator.pureAlcoholRemainingMl(
      volumeRemainingMl,
      session.alcoholPercent,
    );
    final beerPrice = StatsCalculator.pricePerReferenceBeer(
      session.kegPrice,
      session.volumeTotalMl,
      unit: prefs.volumeUnit,
    );
    final endReference = session.status == KegStatus.done
        ? session.endTime ??
              pours
                  .where((p) => !p.undone)
                  .map((p) => p.timestamp)
                  .fold<DateTime?>(null, (max, ts) {
                    if (max == null || ts.isAfter(max)) return ts;
                    return max;
                  }) ??
              DateTime.now()
        : DateTime.now();
    final elapsed = session.startTime != null
        ? endReference.difference(session.startTime!)
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context)!.kegInformation),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Brewery section (only when brewery info is available)
          if (_hasBreweryInfo(session)) ...[
            _buildSectionHeader(context, AppLocalizations.of(context)!.brewery),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.brewery != null)
                      ..._breweryRow(context, null, session.brewery!),
                    if (session.breweryAddress != null)
                      ..._breweryRow(
                        context,
                        AppLocalizations.of(context)!.breweryAddress,
                        session.breweryAddress!,
                      ),
                    if (session.breweryRegion != null)
                      ..._breweryRow(
                        context,
                        AppLocalizations.of(context)!.breweryRegion,
                        session.breweryRegion!,
                      ),
                    if (session.breweryYearFounded != null)
                      ..._breweryRow(
                        context,
                        AppLocalizations.of(context)!.breweryYearFounded,
                        session.breweryYearFounded!,
                      ),
                    if (session.breweryWebsite != null)
                      _buildWebsiteRow(context, session.breweryWebsite!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Beer Information Section
          _buildSectionHeader(
            context,
            AppLocalizations.of(context)!.beerInformation,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.beerName,
                    session.beerName,
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.alcoholPercent,
                    '${session.alcoholPercent.toStringAsFixed(1)}%',
                  ),
                  if (session.malt != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.malt,
                      session.malt!,
                    ),
                  ],
                  if (session.fermentation != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.fermentation,
                      session.fermentation!,
                    ),
                  ],
                  if (session.beerType != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.beerType,
                      session.beerType!,
                    ),
                  ],
                  if (session.beerGroup != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.beerGroup,
                      session.beerGroup!,
                    ),
                  ],
                  if (session.beerStyle != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.beerStyle,
                      session.beerStyle!,
                    ),
                  ],
                  if (session.degreePlato != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.degreePlato,
                      session.degreePlato!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Keg Information Section
          _buildSectionHeader(
            context,
            AppLocalizations.of(context)!.kegInformation,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.totalVolume,
                    TimeFormatter.formatVolumeMl(
                      session.volumeTotalMl,
                      prefs: prefs,
                    ),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.price,
                    TimeFormatter.formatCurrency(
                      session.kegPrice,
                      prefs: prefs,
                    ),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.status,
                    _formatStatus(context, session.status),
                  ),
                  if (session.startTime != null) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.started,
                      _formatDateTime(session.startTime!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Session Statistics Section
          if (session.startTime != null) ...[
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sessionStatistics,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.volumeConsumed,
                      TimeFormatter.formatVolumeMl(totalPouredMl, prefs: prefs),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.volumeRemaining2,
                      TimeFormatter.formatVolumeMl(
                        volumeRemainingMl,
                        prefs: prefs,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.alcoholConsumed,
                      TimeFormatter.formatAlcoholMl(
                        alcoholConsumedMl,
                        prefs: prefs,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.alcoholRemaining,
                      TimeFormatter.formatAlcoholMl(
                        alcoholRemainingMl,
                        prefs: prefs,
                      ),
                    ),
                    if (beerPrice != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.pricePerBeer(
                          StatsCalculator.referenceBeerLabel(prefs.volumeUnit),
                        ),
                        TimeFormatter.formatCurrency(beerPrice, prefs: prefs),
                      ),
                    ],
                    if (elapsed != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.elapsedTime,
                        TimeFormatter.formatDuration(elapsed),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Charts section (only shown when session has been started)
          if (session.startTime != null && pours.isNotEmpty) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullscreenChartScreen(
                    session: session,
                    pours: pours,
                    chartType: 'volume',
                    prefs: prefs,
                  ),
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: KegVolumeChart(
                    session: session,
                    pours: pours,
                    prefs: prefs,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullscreenChartScreen(
                    session: session,
                    pours: pours,
                    chartType: 'rate',
                    prefs: prefs,
                  ),
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PourRateChart(session: session, pours: pours),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  bool _hasBreweryInfo(KegSession session) =>
      session.brewery != null ||
      session.breweryAddress != null ||
      session.breweryRegion != null ||
      session.breweryYearFounded != null ||
      session.breweryWebsite != null;

  /// Returns a divider + info row pair, or just an info row if [label] is null.
  List<Widget> _breweryRow(BuildContext context, String? label, String value) {
    final isFirst = label == null;
    return [
      if (!isFirst) const Divider(height: 16),
      _buildInfoRow(context, label ?? '', value),
    ];
  }

  Widget _buildWebsiteRow(BuildContext context, String url) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                l.breweryWebsite,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: BeerColors.primaryAmber,
                    decoration: TextDecoration.underline,
                    decorationColor: BeerColors.primaryAmber,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: BeerColors.primaryAmber,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: BeerColors.onSurfaceSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatStatus(BuildContext context, KegStatus status) {
    final l = AppLocalizations.of(context)!;
    switch (status) {
      case KegStatus.created:
        return l.statusCreated;
      case KegStatus.active:
        return l.statusActive;
      case KegStatus.paused:
        return l.statusPaused;
      case KegStatus.done:
        return l.statusDone;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy HH:mm');
    return formatter.format(dateTime);
  }
}
