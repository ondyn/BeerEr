import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeFormatter.formatDuration', () {
    group('positive durations', () {
      test('zero seconds', () {
        expect(TimeFormatter.formatDuration(Duration.zero), '0s');
      });

      test('seconds only', () {
        expect(TimeFormatter.formatDuration(const Duration(seconds: 45)), '45s');
        expect(TimeFormatter.formatDuration(const Duration(seconds: 1)), '1s');
        expect(TimeFormatter.formatDuration(const Duration(seconds: 59)), '59s');
      });

      test('minutes and seconds', () {
        expect(
          TimeFormatter.formatDuration(
            const Duration(minutes: 3, seconds: 5),
          ),
          '3m 05s',
        );
        expect(
          TimeFormatter.formatDuration(
            const Duration(minutes: 59, seconds: 59),
          ),
          '59m 59s',
        );
      });

      test('hours and minutes', () {
        expect(
          TimeFormatter.formatDuration(
            const Duration(hours: 2, minutes: 4),
          ),
          '2h 04m',
        );
        expect(
          TimeFormatter.formatDuration(
            const Duration(hours: 1, minutes: 0),
          ),
          '1h 00m',
        );
      });

      test('hours boundary: 60 minutes shows as 1 hour', () {
        expect(
          TimeFormatter.formatDuration(const Duration(minutes: 60)),
          '1h 00m',
        );
      });
    });

    group('negative durations (clock-skew guard)', () {
      test('small negative — returns 0s', () {
        expect(
          TimeFormatter.formatDuration(const Duration(seconds: -1)),
          '0s',
        );
      });

      test('large negative — returns 0s', () {
        expect(
          TimeFormatter.formatDuration(const Duration(minutes: -5)),
          '0s',
        );
        expect(
          TimeFormatter.formatDuration(const Duration(hours: -2)),
          '0s',
        );
      });

      test('Duration(-1ms) — returns 0s', () {
        expect(
          TimeFormatter.formatDuration(const Duration(milliseconds: -1)),
          '0s',
        );
      });
    });
  });

  group('TimeFormatter.formatTimer', () {
    group('positive durations', () {
      test('zero shows 00:00', () {
        expect(TimeFormatter.formatTimer(Duration.zero), '00:00');
      });

      test('seconds only', () {
        expect(
          TimeFormatter.formatTimer(const Duration(seconds: 7)),
          '00:07',
        );
        expect(
          TimeFormatter.formatTimer(const Duration(seconds: 59)),
          '00:59',
        );
      });

      test('minutes and seconds', () {
        expect(
          TimeFormatter.formatTimer(
            const Duration(minutes: 3, seconds: 5),
          ),
          '03:05',
        );
        expect(
          TimeFormatter.formatTimer(
            const Duration(minutes: 59, seconds: 59),
          ),
          '59:59',
        );
      });

      test('hours, minutes and seconds', () {
        expect(
          TimeFormatter.formatTimer(
            const Duration(hours: 1, minutes: 2, seconds: 3),
          ),
          '01:02:03',
        );
        expect(
          TimeFormatter.formatTimer(
            const Duration(hours: 10, minutes: 0, seconds: 0),
          ),
          '10:00:00',
        );
      });
    });

    group('negative durations (clock-skew guard)', () {
      test('small negative — returns 00:00', () {
        expect(
          TimeFormatter.formatTimer(const Duration(seconds: -5)),
          '00:00',
        );
      });

      test('large negative — returns 00:00', () {
        expect(
          TimeFormatter.formatTimer(const Duration(minutes: -10)),
          '00:00',
        );
        expect(
          TimeFormatter.formatTimer(const Duration(hours: -1)),
          '00:00',
        );
      });
    });
  });

  group('TimeFormatter.formatVolumeMl', () {
    test('below 1000 ml shows ml', () {
      expect(TimeFormatter.formatVolumeMl(500), '500 ml');
      expect(TimeFormatter.formatVolumeMl(0), '0 ml');
      expect(TimeFormatter.formatVolumeMl(999), '999 ml');
    });

    test('1000 ml or more shows litres', () {
      expect(TimeFormatter.formatVolumeMl(1000), '1.0 l');
      expect(TimeFormatter.formatVolumeMl(5000), '5.0 l');
      expect(TimeFormatter.formatVolumeMl(1500), '1.5 l');
    });

    test('pints unit', () {
      const prefs = FormatPreferences(volumeUnit: VolumeUnit.pints);
      // 568.261 ml ≈ 1 pt
      final result = TimeFormatter.formatVolumeMl(568.261, prefs: prefs);
      expect(result, '1.0 pt');
    });

    test('US fl oz unit', () {
      const prefs = FormatPreferences(volumeUnit: VolumeUnit.usFlOz);
      // 29.5735 ml ≈ 1 fl oz
      final result = TimeFormatter.formatVolumeMl(29.5735, prefs: prefs);
      expect(result, '1.0 fl oz');
    });
  });

  group('TimeFormatter.formatPercent', () {
    test('rounds to nearest integer', () {
      expect(TimeFormatter.formatPercent(42.6), '43%');
      expect(TimeFormatter.formatPercent(100.0), '100%');
      expect(TimeFormatter.formatPercent(0.0), '0%');
    });
  });

  group('TimeFormatter.formatRatio', () {
    test('0.5 → 50%', () {
      expect(TimeFormatter.formatRatio(0.5), '50%');
    });

    test('0.0 → 0%', () {
      expect(TimeFormatter.formatRatio(0.0), '0%');
    });

    test('1.0 → 100%', () {
      expect(TimeFormatter.formatRatio(1.0), '100%');
    });
  });

  group('TimeFormatter.formatCurrency', () {
    test('default symbol and 2 decimal places', () {
      expect(TimeFormatter.formatCurrency(12.5), '12.50 €');
    });

    test('custom symbol', () {
      expect(
        TimeFormatter.formatCurrency(9.99, symbol: '€'),
        '9.99 €',
      );
    });

    test('zero decimal places', () {
      expect(
        TimeFormatter.formatCurrency(100.0, symbol: '€', decimalPlaces: 0),
        '100 €',
      );
    });
  });

  group('TimeFormatter.formatBac', () {
    test('formats with 2 decimal places and ‰ suffix', () {
      expect(TimeFormatter.formatBac(1.234), '1.23 ‰');
    });

    test('zero BAC', () {
      expect(TimeFormatter.formatBac(0.0), '0.00 ‰');
    });

    test('custom fraction digits', () {
      expect(TimeFormatter.formatBac(0.5, fractionDigits: 1), '0.5 ‰');
    });
  });
}
