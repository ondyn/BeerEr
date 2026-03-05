import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'keg_session.freezed.dart';
part 'keg_session.g.dart';

enum KegStatus { active, paused, done }

@freezed
class KegSession with _$KegSession {
  const factory KegSession({
    required String id,
    required String creatorId,
    required String beerName,
    String? untappdBeerId,
    required double volumeTotalMl,
    required double volumeRemainingMl,
    required double pricePerLiter,
    required double alcoholPercent,
    @Default([]) List<double> predefinedVolumesMl,
    DateTime? startTime,
    @Default(KegStatus.active) KegStatus status,
  }) = _KegSession;

  factory KegSession.fromJson(Map<String, dynamic> json) =>
      _$KegSessionFromJson(json);
}
