import 'dart:math' as math;

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
/// Shows "My stats"-equivalent data plus two charts:
///   1. Cumulative beer volume over time
///   2. Estimated BAC over time
class ParticipantDetailScreen extends StatelessWidget {
  const ParticipantDetailScreen({
    super.key,
    required this.user,
    required this.session,
    required this.pours,
    required this.isMe,
    required this.prefs,
  });

  final AppUser user;
  final KegSession session;
  final List<Pour> pours;
  final bool isMe;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final userPours = pours
        .where((p) => p.userId == user.id && !p.undone)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final totalMl = StatsCalculator.userPouredMl(pours, user.id);
    final beerCount = StatsCalculator.beerCount(pours, user.id);
    final pureAlcMl =
        StatsCalculator.userPureAlcoholMl(pours, user.id, session.alcoholPercent);
    final cost = StatsCalculator.userCostByConsumption(
      pours,
      user.id,
      session.kegPrice,
    );
    final ratio = StatsCalculator.userConsumptionRatio(pours, user.id);

    final sessionStart = session.startTime ?? userPours.firstOrNull?.timestamp;
    final sessionDuration = sessionStart != null
        ? DateTime.now().difference(sessionStart)
        : Duration.zero;
    final avgRate =
        StatsCalculator.averageRateMlPerHour(userPours, sessionDuration);

    // BAC (only if weight is set)
    double? bacValue;
    Duration? timeToZero;
    if (user.weightKg > 0 && userPours.isNotEmpty && sessionStart != null) {
      final elapsed = DateTime.now().difference(sessionStart).inMinutes;
      bacValue = BacCalculator.estimateFromPours(
        pours: userPours,
        abv: session.alcoholPercent,
        weightKg: user.weightKg,
        gender: user.gender,
        elapsedMinutes: elapsed,
      );
      timeToZero = BacCalculator.timeToZero(bacValue ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
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
              'CONSUMPTION OVER TIME',
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
              user.weightKg > 0 &&
              sessionStart != null) ...[
            Text(
              'ESTIMATED BAC OVER TIME',
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
                weightKg: user.weightKg,
                gender: user.gender,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠ BAC is an estimate only — do not use it to determine '
              'fitness to drive.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeerColors.warning,
                    fontStyle: FontStyle.italic,
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
          displayName: user.displayName,
          avatarIcon: user.avatarIcon,
          radius: 32,
          isHighlighted: isMe,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName + (isMe ? ' (you)' : ''),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (user.weightKg > 0)
                Text(
                  '${user.weightKg.toStringAsFixed(0)} kg · '
                  '${user.gender == 'male' ? 'Male' : 'Female'}',
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
              'STATS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: '🍺',
              label: 'Beer count',
              value: prefs.formatDecimal(beerCount, 1),
            ),
            _StatRow(
              icon: '📊',
              label: 'Volume',
              value: TimeFormatter.formatVolumeMl(totalMl, prefs: prefs),
            ),
            _StatRow(
              icon: '🧪',
              label: 'Pure alcohol',
              value: '${prefs.formatDecimal(pureAlcMl, 1)} ml',
            ),
            _StatRow(
              icon: '📈',
              label: 'Share of keg',
              value: TimeFormatter.formatRatio(ratio),
            ),
            _StatRow(
              icon: '⏱',
              label: 'Avg. rate',
              value: avgRate > 0
                  ? '${TimeFormatter.formatVolumeMl(avgRate, prefs: prefs)}/h'
                  : '—',
            ),
            _StatRow(
              icon: '💰',
              label: 'Cost',
              value: TimeFormatter.formatCurrency(cost, prefs: prefs),
            ),
            if (bacValue != null) ...[
              const Divider(height: 16),
              _StatRow(
                icon: '🩸',
                label: 'Est. BAC',
                value: '${prefs.formatDecimal(bacValue, 2)} ‰',
              ),
              if (timeToZero != null && bacValue > 0)
                _StatRow(
                  icon: '🚗',
                  label: 'Est. time to drive',
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

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
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
                _formatMinutes(value.toInt()),
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
                _formatMinutes(value.toInt()),
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
  /// Only pours that occurred before the given minute are counted.
  double _bacAtMinute(int minute) {
    final cutoff = sessionStart.add(Duration(minutes: minute));
    final totalAlcGrams = BacCalculator.totalAlcoholGramsFromPours(
      pours,
      abv: alcoholPercent,
      cutoffTime: cutoff,
    );
    return BacCalculator.calculate(
      totalAlcoholGrams: totalAlcGrams,
      weightKg: weightKg,
      gender: gender,
      elapsedMinutes: minute,
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

String _formatMinutes(int totalMinutes) {
  if (totalMinutes < 60) return '${totalMinutes}m';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? '${h}h' : '${h}h${m}m';
}
