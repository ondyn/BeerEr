import 'package:freezed_annotation/freezed_annotation.dart';

part 'keg_session.freezed.dart';
part 'keg_session.g.dart';

enum KegStatus { active, paused, done }

@freezed
abstract class KegSession with _$KegSession {
  const factory KegSession({
    required String id,
    required String creatorId,
    required String beerName,
    String? untappdBeerId,
    required double volumeTotalMl,
    required double volumeRemainingMl,
    required double kegPrice,
    required double alcoholPercent,
    @Default([]) List<double> predefinedVolumesMl,
    DateTime? startTime,
    @Default(KegStatus.active) KegStatus status,
    /// Deep link stored in Firestore so it can be retrieved without recalculation.
    /// Format: beerer://join/[sessionId]
    /// Serialised as join_link in Firestore.
    String? joinLink,
  }) = _KegSession;

  factory KegSession.fromJson(Map<String, dynamic> json) =>
      _$KegSessionFromJson(json);
}
