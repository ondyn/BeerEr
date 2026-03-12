/// Formats durations and timestamps for display.
class TimeFormatter {
  const TimeFormatter._();

  /// Formats a [Duration] as "Xh Ym" or "Ym Zs".
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  /// Formats a duration as "HH:MM:SS" for live counters.
  static String formatTimer(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats a volume in ml to a human-readable string.
  static String formatVolumeMl(double ml) {
    if (ml >= 1000) {
      final litres = ml / 1000;
      return '${litres.toStringAsFixed(1)} l';
    }
    return '${ml.round()} ml';
  }

  /// Formats a percentage (0.0–100.0) for display.
  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(0)}%';
  }

  /// Formats a currency amount.
  static String formatCurrency(double amount, {String symbol = '€'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
