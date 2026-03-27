import 'package:beerer/models/models.dart';
import 'package:beerer/utils/bac_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BacCalculator', () {
    test('returns 0 when no alcohol consumed', () {
      final bac = BacCalculator.calculate(
        totalAlcoholGrams: 0,
        weightKg: 80,
        gender: 'male',
        elapsedMinutes: 0,
      );
      expect(bac, 0.0);
    });

    test('male BAC is lower than female BAC for same intake', () {
      // Use a large dose so neither result collapses to 0 within the time frame
      const grams = 50.0;
      const weight = 70.0;
      const elapsed = 30; // only 30 min — not enough to metabolise 50 g

      final male = BacCalculator.calculate(
        totalAlcoholGrams: grams,
        weightKg: weight,
        gender: 'male',
        elapsedMinutes: elapsed,
      );
      final female = BacCalculator.calculate(
        totalAlcoholGrams: grams,
        weightKg: weight,
        gender: 'female',
        elapsedMinutes: elapsed,
      );

      expect(male, greaterThan(0));
      expect(female, greaterThan(0));
      expect(male, lessThan(female));
    });

    test('BAC decreases over time (metabolism)', () {
      // Use a large dose (60 g) so that after 30 min BAC is still positive,
      // and after 180 min it's lower (though may still be > 0).
      final bacEarly = BacCalculator.calculate(
        totalAlcoholGrams: 60,
        weightKg: 75,
        gender: 'male',
        elapsedMinutes: 30,
      );
      final bacLate = BacCalculator.calculate(
        totalAlcoholGrams: 60,
        weightKg: 75,
        gender: 'male',
        elapsedMinutes: 180,
      );
      expect(bacEarly, greaterThan(0));
      expect(bacLate, lessThan(bacEarly));
    });

    test('BAC never goes below 0', () {
      final bac = BacCalculator.calculate(
        totalAlcoholGrams: 5,
        weightKg: 80,
        gender: 'male',
        elapsedMinutes: 1000, // long after alcohol metabolised
      );
      expect(bac, 0.0);
    });

    test('pureAlcoholGrams calculates correctly for 500ml at 5% ABV', () {
      // 500 * 0.05 * 0.789 ≈ 19.725 g
      final grams = BacCalculator.pureAlcoholGrams(volumeMl: 500, abv: 5.0);
      expect(grams, closeTo(19.725, 0.01));
    });
  });

  group('BacCalculator.calculateFromPours (per-pour metabolism)', () {
    Pour makePour(DateTime timestamp, double volumeMl) {
      return Pour(
        id: 'test',
        sessionId: 'session',
        userId: 'user',
        pouredById: 'user',
        volumeMl: volumeMl,
        timestamp: timestamp,
      );
    }

    test('single pour gives positive BAC', () {
      final now = DateTime(2025, 6, 15, 20, 0);
      final pours = [makePour(now.subtract(const Duration(minutes: 10)), 500)];

      final bac = BacCalculator.calculateFromPours(
        pours: pours,
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        currentTime: now,
      );
      expect(bac, greaterThan(0));
    });

    test('BAC reaches 0 after enough time, then new pour gives fresh BAC', () {
      // First pour at T=0
      final sessionStart = DateTime(2025, 6, 15, 18, 0);
      final firstPour = makePour(sessionStart, 500);

      // After 3 hours, BAC from one beer should be 0
      final after3h = sessionStart.add(const Duration(hours: 3));
      final bacAfterPause = BacCalculator.calculateFromPours(
        pours: [firstPour],
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        currentTime: after3h,
      );
      expect(bacAfterPause, equals(0.0),
          reason: 'BAC should be 0 after 3 hours for one 500ml 5% beer');

      // New pour at T+3h
      final secondPour = makePour(after3h, 500);
      final shortly = after3h.add(const Duration(minutes: 5));

      final bacAfterNewPour = BacCalculator.calculateFromPours(
        pours: [firstPour, secondPour],
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        currentTime: shortly,
      );

      // BAC should be positive because the new pour is fresh
      expect(bacAfterNewPour, greaterThan(0),
          reason: 'BAC should be positive after a new pour following a long break');
    });

    test('undone pours are ignored', () {
      final now = DateTime(2025, 6, 15, 20, 0);
      final pour = Pour(
        id: 'test',
        sessionId: 'session',
        userId: 'user',
        pouredById: 'user',
        volumeMl: 500,
        timestamp: now.subtract(const Duration(minutes: 10)),
        undone: true,
      );

      final bac = BacCalculator.calculateFromPours(
        pours: [pour],
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        currentTime: now,
      );
      expect(bac, equals(0.0));
    });

    test('multiple pours accumulate BAC correctly', () {
      final start = DateTime(2025, 6, 15, 20, 0);
      final pours = [
        makePour(start, 500),
        makePour(start.add(const Duration(minutes: 15)), 500),
        makePour(start.add(const Duration(minutes: 30)), 500),
      ];

      final currentTime = start.add(const Duration(minutes: 35));
      final bac = BacCalculator.calculateFromPours(
        pours: pours,
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        currentTime: currentTime,
      );

      // Three beers in 35 min for 80kg male should give meaningful BAC
      expect(bac, greaterThan(0.5));
    });

    test('estimateFromPours returns null for 0 weight', () {
      final now = DateTime(2025, 6, 15, 20, 0);
      final pours = [
        Pour(
          id: 'test',
          sessionId: 'session',
          userId: 'user',
          pouredById: 'user',
          volumeMl: 500,
          timestamp: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final bac = BacCalculator.estimateFromPours(
        pours: pours,
        abv: 5.0,
        weightKg: 0,
        gender: 'male',
        elapsedMinutes: 10,
        currentTime: now,
      );
      expect(bac, isNull);
    });

    test('estimateFromPours returns null for empty pours', () {
      final bac = BacCalculator.estimateFromPours(
        pours: [],
        abv: 5.0,
        weightKg: 80,
        gender: 'male',
        elapsedMinutes: 10,
      );
      expect(bac, isNull);
    });
  });
}
