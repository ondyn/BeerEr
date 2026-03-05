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
}
