import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
            body: Center(child: Text(AppLocalizations.of(context)!.sessionNotFound)),
          );
        }
        return _KegInfoBody(session: session);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
      ),
    );
  }
}

class _KegInfoBody extends StatelessWidget {
  const _KegInfoBody({required this.session});

  final KegSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context)!.kegInformation),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Beer Information Section
          _buildSectionHeader(context, AppLocalizations.of(context)!.beerInformation),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, AppLocalizations.of(context)!.beerName, session.beerName),
                  const Divider(height: 16),
                  _buildInfoRow(context, AppLocalizations.of(context)!.alcoholPercent,
                      '${session.alcoholPercent.toStringAsFixed(1)}%'),
                  const Divider(height: 16),
                  if (session.brewery != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.brewery, session.brewery!),
                  if (session.brewery != null) const Divider(height: 16),
                  if (session.malt != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.malt, session.malt!),
                  if (session.malt != null) const Divider(height: 16),
                  if (session.fermentation != null)
                    _buildInfoRow(
                        context, AppLocalizations.of(context)!.fermentation, session.fermentation!),
                  if (session.fermentation != null)
                    const Divider(height: 16),
                  if (session.beerType != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.beerType, session.beerType!),
                  if (session.beerType != null) const Divider(height: 16),
                  if (session.beerGroup != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.beerGroup, session.beerGroup!),
                  if (session.beerGroup != null) const Divider(height: 16),
                  if (session.beerStyle != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.beerStyle, session.beerStyle!),
                  if (session.beerStyle != null) const Divider(height: 16),
                  if (session.degreePlato != null)
                    _buildInfoRow(context, AppLocalizations.of(context)!.degreePlato, session.degreePlato!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Keg Information Section
          _buildSectionHeader(context, AppLocalizations.of(context)!.kegInformation),
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
                    TimeFormatter.formatVolumeMl(session.volumeTotalMl),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    context,
                    AppLocalizations.of(context)!.price,
                    TimeFormatter.formatCurrency(session.kegPrice),
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
        ],
      ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
