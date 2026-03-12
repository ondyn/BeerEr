import 'package:beerer/models/models.dart';

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
}
