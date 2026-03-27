import 'dart:math';

import 'package:beerer/models/models.dart';

/// BAC estimation using the Widmark formula.
/// All calculation happens on-device; the result is NEVER stored in Firestore.
class BacCalculator {
  const BacCalculator._();

  /// Returns estimated BAC in ‰ (per mille, g/L) for the given parameters.
  ///
  /// Uses the Widmark formula with per-pour metabolism: each pour's
  /// alcohol is metabolised independently from the time it was consumed.
  /// This correctly handles long pauses where earlier alcohol is fully
  /// metabolised before new drinking begins.
  ///
  /// [pours] — the list of active (non-undone) pours.
  /// [abv] — alcohol by volume as a percentage (e.g. 5.0 for 5%).
  /// [weightKg] — body weight in kilograms.
  /// [gender] — 'male' or 'female' (affects Widmark r factor).
  /// [currentTime] — the time at which BAC is computed (defaults to now).
  static double calculateFromPours({
    required List<Pour> pours,
    required double abv,
    required double weightKg,
    required String gender,
    DateTime? currentTime,
  }) {
    if (weightKg <= 0) return 0;
    final now = currentTime ?? DateTime.now();
    final activePours = pours.where((p) => !p.undone).toList();
    if (activePours.isEmpty) return 0;

    final r = gender == 'female' ? 0.55 : 0.68;

    double totalBac = 0;
    for (final pour in activePours) {
      final alcGrams = pureAlcoholGrams(volumeMl: pour.volumeMl, abv: abv);
      final minutesSincePour = now.difference(pour.timestamp).inMinutes;
      if (minutesSincePour < 0) continue;

      final rawBac = alcGrams / (r * weightKg);
      final metabolised = 0.15 * (minutesSincePour / 60);
      totalBac += max(0, rawBac - metabolised);
    }

    return max(0, totalBac);
  }

  /// Returns estimated BAC in ‰ (per mille, g/L) for the given parameters.
  ///
  /// Uses the classic Widmark formula with a single elapsed time.
  /// NOTE: This method does not handle long pauses well — use
  /// [calculateFromPours] for more accurate results.
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

  /// Computes the total grams of pure alcohol from a list of pours.
  ///
  /// Only active (non-undone) pours are considered. When [cutoffTime]
  /// is provided, only pours with a timestamp on or before that time
  /// are included — useful for charting BAC at past points.
  static double totalAlcoholGramsFromPours(
    List<Pour> pours, {
    required double abv,
    DateTime? cutoffTime,
  }) {
    var filtered = pours.where((p) => !p.undone);
    if (cutoffTime != null) {
      filtered = filtered.where((p) => !p.timestamp.isAfter(cutoffTime));
    }
    return filtered.fold(0.0, (sum, p) {
      return sum + pureAlcoholGrams(volumeMl: p.volumeMl, abv: abv);
    });
  }

  /// Convenience: estimates current BAC from a list of pours in one call.
  ///
  /// Returns `null` when [weightKg] is ≤ 0 or [pours] has no active
  /// pours. Only active (non-undone) pours are counted.
  ///
  /// Uses the per-pour Widmark approach so that long pauses between
  /// drinking sessions are handled correctly (BAC reaches 0, then new
  /// pours contribute fresh BAC).
  static double? estimateFromPours({
    required List<Pour> pours,
    required double abv,
    required double weightKg,
    required String gender,
    required int elapsedMinutes,
    DateTime? currentTime,
  }) {
    if (weightKg <= 0) return null;
    final activePours = pours.where((p) => !p.undone).toList();
    if (activePours.isEmpty) return null;
    return calculateFromPours(
      pours: activePours,
      abv: abv,
      weightKg: weightKg,
      gender: gender,
      currentTime: currentTime,
    );
  }
}
