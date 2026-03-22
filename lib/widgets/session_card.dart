import 'dart:async';

import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:flutter/material.dart';

/// Summary card used in Home and History lists.
///
/// Uses a [StatefulWidget] so the elapsed-time display ticks every minute
/// without requiring the parent to rebuild.
class SessionCard extends StatefulWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.participantCount = 0,
    this.isOwner = false,
    this.onTap,
    this.highlighted = false,
  });

  final KegSession session;
  final int participantCount;
  final bool isOwner;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every minute so the elapsed time stays current.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final fillPercent =
        session.volumeRemainingMl / session.volumeTotalMl;
    final elapsed = session.startTime != null
        ? DateTime.now().difference(session.startTime!)
        : Duration.zero;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.highlighted
            ? const BorderSide(color: BeerColors.primaryAmber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sports_bar,
                    color: BeerColors.primaryAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.beerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.isOwner) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: BeerColors.primaryAmber,
                    ),
                  ],
                  _StatusBadge(status: session.status),
                ],
              ),
              const SizedBox(height: 8),
              if (session.status != KegStatus.done) ...[
                // Mini fill bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercent.clamp(0.0, 1.0),
                    backgroundColor: BeerColors.surfaceVariant,
                    color: BeerColors.primaryAmber,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.percentLeft(TimeFormatter.formatPercent(fillPercent * 100)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.peopleDuration(widget.participantCount, TimeFormatter.formatDuration(elapsed)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final KegStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      KegStatus.created => (l.statusReady, BeerColors.primaryAmber),
      KegStatus.active => (l.statusActive, BeerColors.success),
      KegStatus.paused => (l.statusPaused, BeerColors.warning),
      KegStatus.done => (l.statusDone, BeerColors.onSurfaceSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
