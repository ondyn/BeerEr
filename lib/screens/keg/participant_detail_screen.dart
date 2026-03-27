import 'dart:async';
import 'dart:math' as math;

import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/bac_calculator.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Detail view for a single participant in a keg session.
///
/// Works for both registered [AppUser] and [ManualUser] (guest) participants.
/// Shows stats plus two charts:
///   1. Cumulative beer volume over time
///   2. Estimated BAC over time (only for registered users with weight)
///
/// When [onRemoveGuest] is provided the screen shows a "Remove from session"
/// button (used when the keg creator views a guest's detail).
class ParticipantDetailScreen extends StatefulWidget {
  const ParticipantDetailScreen({
    super.key,
    required this.session,
    required this.pours,
    required this.isMe,
    required this.prefs,
    this.user,
    this.guest,
    this.onRemoveGuest,
  }) : assert(user != null || guest != null);

  final AppUser? user;
  final ManualUser? guest;
  final KegSession session;
  final List<Pour> pours;
  final bool isMe;
  final FormatPreferences prefs;

  /// Called when the keg creator taps "Remove from session" for a guest.
  final VoidCallback? onRemoveGuest;

  @override
  State<ParticipantDetailScreen> createState() =>
      _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  Timer? _ticker;

  KegSession get session => widget.session;
  List<Pour> get pours => widget.pours;
  bool get isMe => widget.isMe;
  FormatPreferences get prefs => widget.prefs;

  String get _participantId => widget.user?.id ?? widget.guest!.id;
  String get _displayName => widget.user?.displayName ?? widget.guest!.nickname;
  bool get _isGuest => widget.guest != null && widget.user == null;
  int? get _avatarIcon => widget.user?.avatarIcon;
  double get _weightKg => widget.user?.weightKg ?? 0;
  String get _gender => widget.user?.gender ?? 'male';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userPours = pours
        .where((p) => p.userId == _participantId && !p.undone)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final totalMl = StatsCalculator.userPouredMl(pours, _participantId);
    final beerCount = StatsCalculator.beerCount(pours, _participantId);
    final pureAlcMl = StatsCalculator.userPureAlcoholMl(
        pours, _participantId, session.alcoholPercent);
    final cost = StatsCalculator.userCostByConsumption(
      pours,
      _participantId,
      session.kegPrice,
    );
    final ratio = StatsCalculator.userConsumptionRatio(pours, _participantId);

    final sessionStart = session.startTime ?? userPours.firstOrNull?.timestamp;
    final sessionDuration = sessionStart != null
        ? DateTime.now().difference(sessionStart)
        : Duration.zero;
    final avgRate =
        StatsCalculator.averageRateMlPerHour(userPours, sessionDuration);
    final timeSinceLast = StatsCalculator.timeSinceLastPour(userPours);

    // BAC (only if weight is set)
    double? bacValue;
    Duration? timeToZero;
    if (_weightKg > 0 && userPours.isNotEmpty && sessionStart != null) {
      final elapsed = DateTime.now().difference(sessionStart).inMinutes;
      bacValue = BacCalculator.estimateFromPours(
        pours: userPours,
        abv: session.alcoholPercent,
        weightKg: _weightKg,
        gender: _gender,
        elapsedMinutes: elapsed,
      );
      timeToZero = BacCalculator.timeToZero(bacValue ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 20),

          // Stats card
          _buildStatsCard(
            context,
            timeSinceLast: timeSinceLast,
            totalMl: totalMl,
            beerCount: beerCount,
            pureAlcMl: pureAlcMl,
            cost: cost,
            ratio: ratio,
            avgRate: avgRate,
            bacValue: bacValue,
            timeToZero: timeToZero,
          ),
          const SizedBox(height: 20),

          // Volume chart
          if (userPours.isNotEmpty && sessionStart != null) ...[
            Text(
              AppLocalizations.of(context)!.consumptionOverTime,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _VolumeChart(
                pours: userPours,
                sessionStart: sessionStart,
                prefs: prefs,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // BAC chart
          if (userPours.isNotEmpty &&
              _weightKg > 0 &&
              sessionStart != null) ...[
            Text(
              AppLocalizations.of(context)!.estimatedBacOverTime,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _BacChart(
                pours: userPours,
                sessionStart: sessionStart,
                alcoholPercent: session.alcoholPercent,
                weightKg: _weightKg,
                gender: _gender,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.bacDoNotUseForDriving,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeerColors.warning,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],

          // Remove guest button (only for guests, shown to keg creator)
          if (_isGuest && widget.onRemoveGuest != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => widget.onRemoveGuest!(),
              icon: const Icon(Icons.person_remove, color: BeerColors.error),
              label: Text(
                AppLocalizations.of(context)!.removeFromSession,
                style: const TextStyle(color: BeerColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: BeerColors.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AvatarCircle(
          displayName: _displayName,
          avatarIcon: _avatarIcon,
          radius: 32,
          isHighlighted: isMe,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName + (isMe ? AppLocalizations.of(context)!.youSuffix : ''),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_isGuest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.guestLower,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
              if (_weightKg > 0)
                Text(
                  '${_weightKg.toStringAsFixed(0)} kg · '
                  '${_gender == 'male' ? AppLocalizations.of(context)!.male : AppLocalizations.of(context)!.female}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required Duration? timeSinceLast,
    required double totalMl,
    required double beerCount,
    required double pureAlcMl,
    required double cost,
    required double ratio,
    required double avgRate,
    required double? bacValue,
    required Duration? timeToZero,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.stats,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.sports_bar_outlined,
              label: AppLocalizations.of(context)!.beerCount,
              value: prefs.formatDecimal(beerCount, 1),
            ),
            _StatRow(
              icon: Icons.local_drink,
              label: AppLocalizations.of(context)!.volume,
              value: TimeFormatter.formatVolumeMl(totalMl, prefs: prefs),
            ),
            _StatRow(
              icon: Icons.bar_chart,
              label: AppLocalizations.of(context)!.shareOfKeg,
              value: TimeFormatter.formatRatio(ratio),
            ),
            if (timeSinceLast != null)
              _StatRow(
                icon: Icons.timer,
                label: AppLocalizations.of(context)!.sinceLast,
                value: TimeFormatter.formatTimer(timeSinceLast),
              ),
            _StatRow(
              icon: Icons.speed,
              label: AppLocalizations.of(context)!.avgRateLabel,
              value: avgRate > 0
                  ? '${TimeFormatter.formatVolumeMl(avgRate, prefs: prefs)}/h'
                  : '—',
            ),
            _StatRow(
              icon: Icons.attach_money,
              label: AppLocalizations.of(context)!.cost,
              value: TimeFormatter.formatCurrency(cost, prefs: prefs),
            ),
            _StatRow(
              icon: Icons.science,
              label: AppLocalizations.of(context)!.pureAlcohol,
              value: '${prefs.formatDecimal(pureAlcMl, 1)} ml',
            ),
            if (bacValue != null) ...[
              const Divider(height: 16),
              _StatRow(
                icon: Icons.science,
                label: AppLocalizations.of(context)!.estBac,
                value: '${prefs.formatDecimal(bacValue, 2)} ‰',
              ),
              if (timeToZero != null && bacValue > 0)
                _StatRow(
                  icon: Icons.directions_car,
                  label: AppLocalizations.of(context)!.estTimeToDrive,
                  value: '~${TimeFormatter.formatDuration(timeToZero)}',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BeerColors.primaryAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
                    )),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cumulative volume over time chart
// ---------------------------------------------------------------------------

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({
    required this.pours,
    required this.sessionStart,
    required this.prefs,
  });

  final List<Pour> pours;
  final DateTime sessionStart;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    // Build cumulative volume spots
    final spots = <FlSpot>[];
    double cumulative = 0;
    // Starting point at 0
    spots.add(const FlSpot(0, 0));
    for (final pour in pours) {
      final minutesSinceStart =
          pour.timestamp.difference(sessionStart).inMinutes.toDouble();
      cumulative += pour.volumeMl;
      spots.add(FlSpot(math.max(0, minutesSinceStart), cumulative));
    }
    // Extend to "now" if session is still running
    final nowMinutes =
        DateTime.now().difference(sessionStart).inMinutes.toDouble();
    if (nowMinutes > (spots.last.x + 1)) {
      spots.add(FlSpot(nowMinutes, cumulative));
    }

    final maxY = (cumulative * 1.15).ceilToDouble();
    final maxX = spots.last.x;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _interval(maxY, 4),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: BeerColors.surfaceVariant,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _interval(maxX, 5),
              getTitlesWidget: (value, meta) => Text(
                _formatRelativeMinutes(value.toInt(), maxX),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: _interval(maxY, 4),
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()} ml',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: BeerColors.primaryAmber,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: BeerColors.primaryAmber,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: BeerColors.primaryAmber.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BAC over time chart
// ---------------------------------------------------------------------------

class _BacChart extends StatelessWidget {
  const _BacChart({
    required this.pours,
    required this.sessionStart,
    required this.alcoholPercent,
    required this.weightKg,
    required this.gender,
  });

  final List<Pour> pours;
  final DateTime sessionStart;
  final double alcoholPercent;
  final double weightKg;
  final String gender;

  @override
  Widget build(BuildContext context) {
    // Sample BAC at every minute from session start to now
    final now = DateTime.now();
    final totalMinutes = now.difference(sessionStart).inMinutes;
    if (totalMinutes <= 0) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    final step = math.max(1, totalMinutes ~/ 120); // at most ~120 points

    for (int m = 0; m <= totalMinutes; m += step) {
      final bac = _bacAtMinute(m);
      spots.add(FlSpot(m.toDouble(), math.max(0, bac)));
    }

    // Ensure the last point is exactly "now"
    if (spots.last.x < totalMinutes) {
      final bac = _bacAtMinute(totalMinutes);
      spots.add(FlSpot(totalMinutes.toDouble(), math.max(0, bac)));
    }

    final maxBac = spots.fold(0.0, (double m, s) => math.max(m, s.y));
    final maxY = math.max(0.5, (maxBac * 1.3 * 10).ceilToDouble() / 10);
    final maxX = spots.last.x;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _interval(maxY, 4),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: BeerColors.surfaceVariant,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _interval(maxX, 5),
              getTitlesWidget: (value, meta) => Text(
                _formatRelativeMinutes(value.toInt(), maxX),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: _interval(maxY, 4),
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(1)} ‰',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: BeerColors.error,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: BeerColors.error.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// Computes BAC at a given minute offset from [sessionStart].
  ///
  /// Uses the per-pour Widmark approach: each pour's alcohol is
  /// metabolised independently from the time it was consumed, so
  /// long pauses are handled correctly.
  double _bacAtMinute(int minute) {
    final cutoff = sessionStart.add(Duration(minutes: minute));
    final poursBeforeCutoff =
        pours.where((p) => !p.undone && !p.timestamp.isAfter(cutoff)).toList();
    return BacCalculator.calculateFromPours(
      pours: poursBeforeCutoff,
      abv: alcoholPercent,
      weightKg: weightKg,
      gender: gender,
      currentTime: cutoff,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a nice axis interval so that there are roughly [desiredTicks]
/// tick marks between 0 and [range].
double _interval(double range, int desiredTicks) {
  if (range <= 0) return 1;
  final raw = range / desiredTicks;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floorToDouble());
  final residual = raw / magnitude;
  double nice;
  if (residual <= 1.5) {
    nice = 1;
  } else if (residual <= 3) {
    nice = 2;
  } else if (residual <= 7) {
    nice = 5;
  } else {
    nice = 10;
  }
  return math.max(1, (nice * magnitude).ceilToDouble());
}

/// Formats an X-axis value (minutes since session start) relative to "now".
///
/// [minuteValue] is the data point, [maxMinutes] is the current total
/// elapsed minutes (i.e. "now"). The right edge shows "now", and earlier
/// values show negative offsets like "-15m", "-1h", etc.
String _formatRelativeMinutes(int minuteValue, double maxMinutes) {
  final diff = minuteValue - maxMinutes.round();
  if (diff.abs() <= 1) return 'now';
  if (diff.abs() < 60) return '${diff}m';
  final h = diff ~/ 60;
  final m = diff.abs() % 60;
  return m == 0 ? '${h}h' : '${h}h${m}m';
}
