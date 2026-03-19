/// User formatting preferences for volume, currency, and decimal display.
class FormatPreferences {
  const FormatPreferences({
    this.volumeUnit = VolumeUnit.litres,
    this.currency = '€',
    this.decimalSeparator = DecimalSeparator.dot,
  });

  final VolumeUnit volumeUnit;
  final String currency;
  final DecimalSeparator decimalSeparator;

  /// Creates [FormatPreferences] from a Firestore preferences map.
  factory FormatPreferences.fromMap(Map<String, dynamic> map) {
    return FormatPreferences(
      volumeUnit: VolumeUnit.fromString(
        map['volume_unit'] as String? ?? 'litres',
      ),
      currency: map['currency'] as String? ?? '€',
      decimalSeparator: DecimalSeparator.fromString(
        map['decimal_separator'] as String? ?? 'dot',
      ),
    );
  }

  /// Serialises to a map suitable for merging into Firestore preferences.
  Map<String, dynamic> toMap() => {
        'volume_unit': volumeUnit.key,
        'currency': currency,
        'decimal_separator': decimalSeparator.key,
      };

  /// Formats a decimal number respecting the user's decimal separator.
  String formatDecimal(double value, int fractionDigits) {
    final raw = value.toStringAsFixed(fractionDigits);
    if (decimalSeparator == DecimalSeparator.comma) {
      return raw.replaceAll('.', ',');
    }
    return raw;
  }
}

/// Supported volume unit systems.
enum VolumeUnit {
  litres('litres', 'Litres'),
  pints('pints', 'Pints'),
  usFlOz('us_fl_oz', 'US fl. oz');

  const VolumeUnit(this.key, this.label);
  final String key;
  final String label;

  static VolumeUnit fromString(String value) {
    return VolumeUnit.values.firstWhere(
      (v) => v.key == value,
      orElse: () => VolumeUnit.litres,
    );
  }
}

/// Decimal separator preference.
enum DecimalSeparator {
  dot('dot', '.'),
  comma('comma', ',');

  const DecimalSeparator(this.key, this.label);
  final String key;
  final String label;

  static DecimalSeparator fromString(String value) {
    return DecimalSeparator.values.firstWhere(
      (v) => v.key == value,
      orElse: () => DecimalSeparator.dot,
    );
  }
}
