import 'package:beerer/utils/format_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormatPreferences', () {
    test('default values', () {
      const prefs = FormatPreferences();
      expect(prefs.volumeUnit, VolumeUnit.litres);
      expect(prefs.currency, '€');
      expect(prefs.decimalSeparator, DecimalSeparator.dot);
    });

    group('fromMap', () {
      test('parses all fields', () {
        final prefs = FormatPreferences.fromMap(const {
          'volume_unit': 'pints',
          'currency': '£',
          'decimal_separator': 'comma',
        });
        expect(prefs.volumeUnit, VolumeUnit.pints);
        expect(prefs.currency, '£');
        expect(prefs.decimalSeparator, DecimalSeparator.comma);
      });

      test('uses defaults for missing fields', () {
        final prefs = FormatPreferences.fromMap(const {});
        expect(prefs.volumeUnit, VolumeUnit.litres);
        expect(prefs.currency, '€');
        expect(prefs.decimalSeparator, DecimalSeparator.dot);
      });
    });

    group('withCurrency', () {
      test('returns copy with new currency, preserving other fields', () {
        const original = FormatPreferences(
          volumeUnit: VolumeUnit.pints,
          currency: '€',
          decimalSeparator: DecimalSeparator.comma,
        );
        final changed = original.withCurrency('Kč');
        expect(changed.currency, 'Kč');
        expect(changed.volumeUnit, VolumeUnit.pints);
        expect(changed.decimalSeparator, DecimalSeparator.comma);
      });
    });

    group('toMap', () {
      test('serialises correctly', () {
        const prefs = FormatPreferences(
          volumeUnit: VolumeUnit.usFlOz,
          currency: r'$',
          decimalSeparator: DecimalSeparator.dot,
        );
        expect(prefs.toMap(), {
          'volume_unit': 'us_fl_oz',
          'currency': r'$',
          'decimal_separator': 'dot',
        });
      });
    });

    group('formatDecimal', () {
      test('dot separator', () {
        const prefs = FormatPreferences(
          decimalSeparator: DecimalSeparator.dot,
        );
        expect(prefs.formatDecimal(3.14159, 2), '3.14');
      });

      test('comma separator', () {
        const prefs = FormatPreferences(
          decimalSeparator: DecimalSeparator.comma,
        );
        expect(prefs.formatDecimal(3.14159, 2), '3,14');
      });

      test('zero fraction digits', () {
        const prefs = FormatPreferences();
        expect(prefs.formatDecimal(99.7, 0), '100');
      });
    });
  });

  group('VolumeUnit', () {
    test('fromString parses known values', () {
      expect(VolumeUnit.fromString('litres'), VolumeUnit.litres);
      expect(VolumeUnit.fromString('pints'), VolumeUnit.pints);
      expect(VolumeUnit.fromString('us_fl_oz'), VolumeUnit.usFlOz);
    });

    test('fromString defaults to litres for unknown', () {
      expect(VolumeUnit.fromString('unknown'), VolumeUnit.litres);
    });
  });

  group('DecimalSeparator', () {
    test('fromString parses known values', () {
      expect(DecimalSeparator.fromString('dot'), DecimalSeparator.dot);
      expect(DecimalSeparator.fromString('comma'), DecimalSeparator.comma);
    });

    test('fromString defaults to dot for unknown', () {
      expect(DecimalSeparator.fromString('xyz'), DecimalSeparator.dot);
    });
  });
}
