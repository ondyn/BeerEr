import 'dart:math';

/// BAC estimation using the Widmark formula.
/// All calculation happens on-device; the result is NEVER stored in Firestore.
class BacCalculator {
  const BacCalculator._();

  /// Returns estimated BAC in ‰ (per mille, g/L) for the given parameters.
  ///
  /// Uses the Widmark formula:
  ///   BAC (g/dL) = A / (r × W_kg × 10)
  ///   BAC (‰)    = BAC (g/dL) × 10
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

    // BAC in g/dL = A / (r × W_kg × 10)
    // BAC in ‰    = BAC_gdL × 10 = A / (r × W_kg)
    final rawBacPromille = totalAlcoholGrams / (r * weightKg);

    // Metabolism rate: ~0.15 ‰ per hour (Widmark β)
    final metabolised = 0.15 * (elapsedMinutes / 60);

    return max(0, rawBacPromille - metabolised);
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
  /// The body metabolises alcohol at approximately 0.15 ‰ per hour.
  /// Returns `null` when the current BAC is already 0.
  static Duration? timeToZero(double currentBacPromille) {
    if (currentBacPromille <= 0) return null;
    // hours = BAC(‰) / metabolic rate (‰/h)
    final hours = currentBacPromille / 0.15;
    return Duration(minutes: (hours * 60).ceil());
  }
}
