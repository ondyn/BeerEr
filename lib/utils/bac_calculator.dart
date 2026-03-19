import 'dart:math';

/// BAC estimation using the Widmark formula.
/// All calculation happens on-device; the result is NEVER stored in Firestore.
class BacCalculator {
  const BacCalculator._();

  /// Returns estimated BAC (g/dL) for the given parameters.
  ///
  /// [totalAlcoholGrams] — total grams of pure alcohol consumed.
  /// [weightKg] — body weight in kilograms.
  /// [gender] — 'male' or 'female' (affects Widmark r factor).
  /// [elapsedMinutes] — minutes since first drink.
  static double calculate({
    required double totalAlcoholGrams,
    required double weightKg,
    required String gender,
    required int elapsedMinutes,
  }) {
    assert(weightKg > 0, 'Weight must be positive');
    assert(elapsedMinutes >= 0, 'Elapsed time cannot be negative');

    // Widmark r factor: 0.68 for male, 0.55 for female
    final r = gender == 'female' ? 0.55 : 0.68;

    // Body water constant (g → dL conversion)
    // BAC (g/dL) = A / (r * W * 10) - (0.015 * t/60)
    final weightG = weightKg * 1000;
    final rawBac = totalAlcoholGrams / (r * weightG * 0.1);
    final metabolised = 0.015 * (elapsedMinutes / 60);

    return max(0, rawBac - metabolised);
  }

  /// Converts a volume of beer to grams of pure alcohol.
  /// [volumeMl] — volume in millilitres.
  /// [abv] — alcohol by volume as a percentage (e.g. 5.0 for 5%).
  static double pureAlcoholGrams({
    required double volumeMl,
    required double abv,
  }) {
    // Density of ethanol ≈ 0.789 g/mL
    return volumeMl * (abv / 100) * 0.789;
  }

  /// Estimated duration until BAC reaches 0 (sober / "ready to drive").
  ///
  /// The body metabolises alcohol at approximately 0.015 g/dL per hour.
  /// Returns `null` when the current BAC is already 0.
  static Duration? timeToZero(double currentBac) {
    if (currentBac <= 0) return null;
    // hours = BAC / metabolic rate
    final hours = currentBac / 0.015;
    return Duration(minutes: (hours * 60).ceil());
  }
}
