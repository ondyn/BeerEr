import 'package:beerer/utils/format_preferences.dart';

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
  ///
  /// When [prefs] is provided, the value is converted to the user's
  /// preferred unit system and formatted with the correct decimal
  /// separator.
  static String formatVolumeMl(double ml, {FormatPreferences? prefs}) {
    final p = prefs ?? const FormatPreferences();

    switch (p.volumeUnit) {
      case VolumeUnit.litres:
        if (ml >= 1000) {
          return '${p.formatDecimal(ml / 1000, 1)} l';
        }
        return '${ml.round()} ml';

      case VolumeUnit.pints:
        // 1 imperial pint ≈ 568.261 ml
        final pints = ml / 568.261;
        return '${p.formatDecimal(pints, 1)} pt';

      case VolumeUnit.usFlOz:
        // 1 US fl oz ≈ 29.5735 ml
        final oz = ml / 29.5735;
        return '${p.formatDecimal(oz, 1)} fl oz';
    }
  }

  /// Formats a percentage (0.0–100.0) for display.
  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(0)}%';
  }

  /// Formats a ratio (0.0–1.0) as a rounded percentage string.
  ///
  /// Example: `0.42` → `"42%"`.
  static String formatRatio(double ratio) {
    return '${(ratio * 100).toStringAsFixed(0)}%';
  }

  /// Formats a beer count (e.g. `2.3`) respecting the user's decimal
  /// separator when [prefs] is provided.
  static String formatBeerCount(double count, {FormatPreferences? prefs}) {
    final p = prefs ?? const FormatPreferences();
    return p.formatDecimal(count, 1);
  }

  /// Formats a BAC value in ‰ (per mille) for display.
  ///
  /// Uses [fractionDigits] decimal places (default 2) and appends ` ‰`.
  static String formatBac(
    double bac, {
    int fractionDigits = 2,
    FormatPreferences? prefs,
  }) {
    final p = prefs ?? const FormatPreferences();
    return '${p.formatDecimal(bac, fractionDigits)} ‰';
  }

  /// Formats a currency amount.
  ///
  /// When [prefs] is provided, the user's chosen currency symbol and
  /// decimal separator are applied.
  static String formatCurrency(
    double amount, {
    String? symbol,
    FormatPreferences? prefs,
  }) {
    final p = prefs ?? const FormatPreferences();
    final sym = symbol ?? p.currency;
    return '${p.formatDecimal(amount, 2)} $sym';
  }
}
