import 'package:beerer/models/models.dart';
import 'package:beerer/utils/format_preferences.dart';

/// Calculates session statistics client-side.
class StatsCalculator {
  const StatsCalculator._();

  /// Total volume poured in a session (excluding undone pours).
  static double totalPouredMl(List<Pour> pours) {
    return pours
        .where((p) => !p.undone)
        .fold(0.0, (sum, p) => sum + p.volumeMl);
  }

  /// Total volume poured by a specific user.
  static double userPouredMl(List<Pour> pours, String userId) {
    return pours
        .where((p) => !p.undone && p.userId == userId)
        .fold(0.0, (sum, p) => sum + p.volumeMl);
  }

  /// Cost for a user based on their share of the total keg volume.
  ///
  /// Formula: kegPrice × (userMl / volumeTotalMl)
  static double userCost(
    List<Pour> pours,
    String userId,
    double kegPrice,
    double volumeTotalMl,
  ) {
    if (volumeTotalMl == 0) return 0;
    final ml = userPouredMl(pours, userId);
    return kegPrice * (ml / volumeTotalMl);
  }

  /// Average drinking rate in ml/hour.
  static double averageRateMlPerHour(
    List<Pour> userPours,
    Duration sessionDuration,
  ) {
    if (sessionDuration.inSeconds == 0) return 0;
    final totalMl = totalPouredMl(userPours);
    return totalMl / (sessionDuration.inSeconds / 3600);
  }

  /// Predicted time until keg is empty based on rolling rate.
  static Duration? predictedTimeUntilEmpty(
    KegSession session,
    List<Pour> allPours,
  ) {
    if (session.startTime == null) return null;
    final elapsed = DateTime.now().difference(session.startTime!);
    if (elapsed.inSeconds == 0) return null;

    final totalPoured = totalPouredMl(allPours);
    if (totalPoured == 0) return null;

    final ratePerSecond = totalPoured / elapsed.inSeconds;
    final remainingMl = session.volumeRemainingMl;
    final secondsLeft = remainingMl / ratePerSecond;

    return Duration(seconds: secondsLeft.round());
  }

  /// Time since the user's last pour.
  static Duration? timeSinceLastPour(List<Pour> userPours) {
    final activePours = userPours.where((p) => !p.undone).toList();
    if (activePours.isEmpty) return null;
    activePours.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return DateTime.now().difference(activePours.first.timestamp);
  }

  /// Duration the user has been drinking their current beer.
  static Duration? currentBeerDuration(List<Pour> userPours) {
    final activePours = userPours.where((p) => !p.undone).toList();
    if (activePours.isEmpty) return null;
    activePours.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return DateTime.now().difference(activePours.first.timestamp);
  }

  /// Total cost for a group of users (joint account).
  static double groupCost(
    List<Pour> pours,
    List<String> userIds,
    double kegPrice,
    double volumeTotalMl,
  ) {
    return userIds.fold(
      0.0,
      (sum, uid) => sum + userCost(pours, uid, kegPrice, volumeTotalMl),
    );
  }

  /// Price per reference beer (0.5 l for litres, 1 pint for pints,
  /// 16 fl oz for US fl oz).
  ///
  /// Returns null when [volumeTotalMl] is zero.
  static double? pricePerReferenceBeer(
    double kegPrice,
    double volumeTotalMl, {
    VolumeUnit unit = VolumeUnit.litres,
  }) {
    if (volumeTotalMl <= 0) return null;

    final double referenceMl;
    switch (unit) {
      case VolumeUnit.litres:
        referenceMl = 500; // 0.5 l
      case VolumeUnit.pints:
        referenceMl = 568.261; // 1 imperial pint
      case VolumeUnit.usFlOz:
        referenceMl = 473.176; // 16 US fl oz (US pint)
    }

    return kegPrice / volumeTotalMl * referenceMl;
  }

  /// Human-readable label for the reference beer size.
  static String referenceBeerLabel(VolumeUnit unit) {
    switch (unit) {
      case VolumeUnit.litres:
        return '0.5 l beer';
      case VolumeUnit.pints:
        return '1 pint';
      case VolumeUnit.usFlOz:
        return '16 fl oz';
    }
  }

  /// Cost for a user based on their share of the actual total consumption
  /// (sum of all pours), not the initial keg volume.
  ///
  /// This gives fairer billing when the keg isn't fully consumed.
  /// Formula: kegPrice × (userMl / totalPouredMl)
  static double userCostByConsumption(
    List<Pour> pours,
    String userId,
    double kegPrice,
  ) {
    final total = totalPouredMl(pours);
    if (total == 0) return 0;
    final ml = userPouredMl(pours, userId);
    return kegPrice * (ml / total);
  }

  /// The consumption ratio for a user (0.0–1.0) relative to the total
  /// poured volume across all participants.
  static double userConsumptionRatio(List<Pour> pours, String userId) {
    final total = totalPouredMl(pours);
    if (total == 0) return 0;
    return userPouredMl(pours, userId) / total;
  }

  /// Cost for a group of users based on actual consumption.
  static double groupCostByConsumption(
    List<Pour> pours,
    List<String> userIds,
    double kegPrice,
  ) {
    return userIds.fold(
      0.0,
      (sum, uid) => sum + userCostByConsumption(pours, uid, kegPrice),
    );
  }

  // --------------------------------------------------------------------------
  // Slowdown detection
  // --------------------------------------------------------------------------

  /// Detects whether the user has significantly slowed down their drinking
  /// pace compared to their session average.
  ///
  /// Returns `true` when:
  /// 1. The user has at least [minPours] active pours.
  /// 2. The time since their last pour exceeds [recentRatioThreshold] times
  ///    the user's average interval between pours.
  ///
  /// [recentRatioThreshold] defaults to **2.0** — i.e. the user hasn't
  /// poured for at least twice their average inter-pour interval.
  /// [minPours] defaults to **3** to avoid noisy detections early on.
  static bool isSlowingDown(
    List<Pour> userPours, {
    double recentRatioThreshold = 2.0,
    int minPours = 3,
  }) {
    final active = userPours.where((p) => !p.undone).toList();
    if (active.length < minPours) return false;

    // Sort oldest → newest.
    active.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Average interval between consecutive pours.
    final intervals = <Duration>[];
    for (var i = 1; i < active.length; i++) {
      intervals.add(active[i].timestamp.difference(active[i - 1].timestamp));
    }
    final avgIntervalSec =
        intervals.fold(0, (int s, d) => s + d.inSeconds) / intervals.length;

    if (avgIntervalSec <= 0) return false;

    // Time since the most recent pour.
    final sinceLastPour =
        DateTime.now().difference(active.last.timestamp).inSeconds;

    return sinceLastPour > avgIntervalSec * recentRatioThreshold;
  }
}
