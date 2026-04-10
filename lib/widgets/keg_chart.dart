import 'dart:math' as math;

import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Chart showing keg volume remaining over time as pours deplete it.
class KegVolumeChart extends StatelessWidget {
  const KegVolumeChart({
    super.key,
    required this.session,
    required this.pours,
    required this.prefs,
    this.chartEndTime,
  });

  final KegSession session;
  final List<Pour> pours;
  final FormatPreferences prefs;
  final DateTime? chartEndTime;

  @override
  Widget build(BuildContext context) {
    final startTime = session.startTime;
    if (startTime == null) return const SizedBox.shrink();

    final activePours =
        pours.where((p) => !p.undone && p.sessionId == session.id).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (activePours.isEmpty) return const SizedBox.shrink();

    // Build step-down spots: volume remaining after each pour
    final spots = <FlSpot>[];
    var remaining = session.volumeTotalMl;
    spots.add(FlSpot(0, remaining));

    for (final pour in activePours) {
      final minutes = pour.timestamp.difference(startTime).inMinutes.toDouble();
      remaining -= pour.volumeMl;
      spots.add(FlSpot(math.max(0, minutes), math.max(0, remaining)));
    }

    final effectiveEndTime =
        chartEndTime ??
        (session.status == KegStatus.done
            ? session.endTime ??
                  activePours.lastOrNull?.timestamp ??
                  DateTime.now()
            : DateTime.now());

    // Extend to effective end time
    final nowMinutes = effectiveEndTime
        .difference(startTime)
        .inMinutes
        .toDouble();
    if (nowMinutes > spots.last.x + 1) {
      spots.add(FlSpot(nowMinutes, remaining));
    }

    final maxY = session.volumeTotalMl * 1.05;
    final maxX = spots.last.x;
    final hourInterval = _hourInterval(maxX);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.kegVolumeChart,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: BeerColors.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
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
                    interval: hourInterval,
                    getTitlesWidget: (value, meta) {
                      // Hide labels too close to min/max to avoid overlap
                      if ((value - meta.min).abs() < hourInterval * 0.3 &&
                          value != meta.min) {
                        return const SizedBox.shrink();
                      }
                      if ((value - meta.max).abs() < hourInterval * 0.3 &&
                          value != meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _formatAsClockTime(startTime, value.toInt(), maxX),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: _interval(maxY, 4),
                    getTitlesWidget: (value, meta) => Text(
                      TimeFormatter.formatVolumeMl(value, prefs: prefs),
                      style: const TextStyle(fontSize: 9),
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
                    show: activePours.length < 50,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 2,
                          color: BeerColors.primaryAmber,
                          strokeWidth: 0,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: BeerColors.primaryAmber.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Chart showing pour rate (pours per hour) over time using a sliding window.
class PourRateChart extends StatelessWidget {
  const PourRateChart({
    super.key,
    required this.session,
    required this.pours,
    this.chartEndTime,
  });

  final KegSession session;
  final List<Pour> pours;
  final DateTime? chartEndTime;

  @override
  Widget build(BuildContext context) {
    final startTime = session.startTime;
    if (startTime == null) return const SizedBox.shrink();

    final activePours =
        pours.where((p) => !p.undone && p.sessionId == session.id).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (activePours.length < 2) return const SizedBox.shrink();

    final now =
        chartEndTime ??
        (session.status == KegStatus.done
            ? session.endTime ??
                  activePours.lastOrNull?.timestamp ??
                  DateTime.now()
            : DateTime.now());
    final totalMinutes = now.difference(startTime).inMinutes;
    if (totalMinutes <= 0) return const SizedBox.shrink();

    // Compute rate in a 30-minute sliding window
    const windowMinutes = 30;
    final step = math.max(1, totalMinutes ~/ 80);
    final spots = <FlSpot>[];

    for (var m = 0; m <= totalMinutes; m += step) {
      final windowStart = startTime.add(Duration(minutes: m - windowMinutes));
      final windowEnd = startTime.add(Duration(minutes: m));
      final windowPours = activePours
          .where(
            (p) =>
                p.timestamp.isAfter(windowStart) &&
                !p.timestamp.isAfter(windowEnd),
          )
          .length;
      final rate = windowPours * (60.0 / windowMinutes);
      spots.add(FlSpot(m.toDouble(), rate));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final maxRate = spots.fold(0.0, (double m, s) => math.max(m, s.y));
    final maxY = math.max(2.0, (maxRate * 1.2).ceilToDouble());
    final maxX = spots.last.x;
    final hourInterval = _hourInterval(maxX);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.pourRateChart,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: BeerColors.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
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
                    interval: hourInterval,
                    getTitlesWidget: (value, meta) {
                      // Hide labels too close to min/max to avoid overlap
                      if ((value - meta.min).abs() < hourInterval * 0.3 &&
                          value != meta.min) {
                        return const SizedBox.shrink();
                      }
                      if ((value - meta.max).abs() < hourInterval * 0.3 &&
                          value != meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _formatAsClockTime(startTime, value.toInt(), maxX),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: _interval(maxY, 4),
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
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
                  color: BeerColors.success,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: BeerColors.success.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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

/// Returns an interval in minutes that aligns to round hours.
///
/// Scales up for very long sessions so labels never overlap.
double _hourInterval(double totalMinutes) {
  if (totalMinutes <= 60) return 15;
  if (totalMinutes <= 120) return 30;
  if (totalMinutes <= 360) return 60;
  if (totalMinutes <= 720) return 120;
  if (totalMinutes <= 1440) return 240;
  if (totalMinutes <= 2880) return 480;
  if (totalMinutes <= 5760) return 720;
  if (totalMinutes <= 10080) return 1440;
  return 2880;
}

/// Formats a minute offset from [startTime] as a clock time (e.g. "14:00").
String _formatAsClockTime(
  DateTime startTime,
  int minuteOffset,
  double totalMinutes,
) {
  final time = startTime.add(Duration(minutes: minuteOffset));
  if (totalMinutes > 2880) {
    return '${time.day}.${time.month}.';
  }
  if (totalMinutes > 1440) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '${time.day}.${time.month} $h:$m';
  }
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
