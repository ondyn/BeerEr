import 'package:beerer/models/models.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a minimal [Pour] for testing.
Pour _pour({
  required String userId,
  double volumeMl = 500,
  bool undone = false,
  DateTime? timestamp,
}) {
  return Pour(
    id: 'p_${DateTime.now().microsecondsSinceEpoch}',
    sessionId: 'session1',
    userId: userId,
    pouredById: userId,
    volumeMl: volumeMl,
    timestamp: timestamp ?? DateTime.now(),
    undone: undone,
  );
}

void main() {
  group('StatsCalculator', () {
    group('totalPouredMl', () {
      test('empty list returns 0', () {
        expect(StatsCalculator.totalPouredMl([]), 0.0);
      });

      test('sums active pours only', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 300),
          _pour(userId: 'b', volumeMl: 200),
          _pour(userId: 'a', volumeMl: 100, undone: true),
        ];
        expect(StatsCalculator.totalPouredMl(pours), 500.0);
      });
    });

    group('userPouredMl', () {
      test('returns 0 for unknown user', () {
        final pours = [_pour(userId: 'a', volumeMl: 500)];
        expect(StatsCalculator.userPouredMl(pours, 'unknown'), 0.0);
      });

      test('sums only active pours for specified user', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 300),
          _pour(userId: 'a', volumeMl: 200),
          _pour(userId: 'b', volumeMl: 100),
          _pour(userId: 'a', volumeMl: 150, undone: true),
        ];
        expect(StatsCalculator.userPouredMl(pours, 'a'), 500.0);
      });
    });

    group('userCost', () {
      test('returns 0 when total volume is 0', () {
        expect(StatsCalculator.userCost([], 'a', 100, 0), 0.0);
      });

      test('calculates proportional cost', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 250),
          _pour(userId: 'b', volumeMl: 750),
        ];
        // User A drank 250 of 1000 total → 25% of 100
        expect(
          StatsCalculator.userCost(pours, 'a', 100, 1000),
          closeTo(25.0, 0.001),
        );
      });
    });

    group('beerCount', () {
      test('returns 0 for no pours', () {
        expect(StatsCalculator.beerCount([], 'a'), 0.0);
      });

      test('counts based on reference volume (default 500 ml)', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 1000),
        ];
        expect(StatsCalculator.beerCount(pours, 'a'), 2.0);
      });

      test('respects custom reference volume', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 568),
        ];
        // 568 ml / 568 ml (1 pint) = 1.0
        expect(
          StatsCalculator.beerCount(pours, 'a', referenceMl: 568),
          closeTo(1.0, 0.001),
        );
      });

      test('excludes undone pours', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 500),
          _pour(userId: 'a', volumeMl: 500, undone: true),
        ];
        expect(StatsCalculator.beerCount(pours, 'a'), 1.0);
      });
    });

    group('averageRateMlPerHour', () {
      test('returns 0 for zero duration', () {
        expect(
          StatsCalculator.averageRateMlPerHour([], Duration.zero),
          0.0,
        );
      });

      test('calculates rate correctly', () {
        final pours = [_pour(userId: 'a', volumeMl: 1000)];
        // 1000 ml in 2 hours = 500 ml/h
        final rate = StatsCalculator.averageRateMlPerHour(
          pours,
          const Duration(hours: 2),
        );
        expect(rate, closeTo(500.0, 0.1));
      });
    });

    group('pricePerReferenceBeer', () {
      test('returns null when volume is 0', () {
        expect(StatsCalculator.pricePerReferenceBeer(100, 0), isNull);
      });

      test('litres: price for 0.5L reference', () {
        // 100 € for 50 L → 100/50000 * 500 = 1.0 € per 0.5L
        expect(
          StatsCalculator.pricePerReferenceBeer(100, 50000),
          closeTo(1.0, 0.001),
        );
      });
    });

    group('groupPouredMl', () {
      test('sums pours for group members', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 300),
          _pour(userId: 'b', volumeMl: 200),
          _pour(userId: 'c', volumeMl: 100),
        ];
        expect(
          StatsCalculator.groupPouredMl(pours, ['a', 'b']),
          500.0,
        );
      });
    });

    group('userConsumptionRatio', () {
      test('returns 0 when no pours', () {
        expect(StatsCalculator.userConsumptionRatio([], 'a'), 0.0);
      });

      test('returns correct ratio', () {
        final pours = [
          _pour(userId: 'a', volumeMl: 300),
          _pour(userId: 'b', volumeMl: 700),
        ];
        expect(
          StatsCalculator.userConsumptionRatio(pours, 'a'),
          closeTo(0.3, 0.001),
        );
      });
    });

    group('pureAlcoholMl', () {
      test('calculates alcohol volume correctly', () {
        final pours = [_pour(userId: 'a', volumeMl: 1000)];
        // 1000 ml of 5% beer = 50 ml pure alcohol
        expect(StatsCalculator.pureAlcoholMl(pours, 5.0), closeTo(50.0, 0.01));
      });
    });
  });
}
