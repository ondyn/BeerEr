import 'package:freezed_annotation/freezed_annotation.dart';

part 'keg_session.freezed.dart';
part 'keg_session.g.dart';

enum KegStatus { created, active, paused, done }

@freezed
abstract class KegSession with _$KegSession {
  const factory KegSession({
    required String id,
    required String creatorId,
    required String beerName,
    required double volumeTotalMl,
    required double volumeRemainingMl,
    required double kegPrice,
    required double alcoholPercent,
    @Default([]) List<double> predefinedVolumesMl,
    DateTime? startTime,
    DateTime? endTime,
    @Default(KegStatus.created) KegStatus status,

    /// Deep link stored in Firestore so it can be retrieved without recalculation.
    /// Format: beerer://join/[sessionId]
    /// Serialised as join_link in Firestore.
    String? joinLink,
    // Beer detail fields sourced from BeerWeb.cz
    String? brewery,
    String? breweryAddress,
    String? breweryRegion,
    String? breweryYearFounded,
    String? breweryWebsite,
    String? malt,
    String? fermentation,
    String? beerType,
    String? beerGroup,
    String? beerStyle,
    String? degreePlato,

    /// Per-participant last used pour volume (ml). Keyed by user ID.
    /// Updated after each pour so the next pour for that user defaults to
    /// their most recent volume.
    @Default({}) Map<String, dynamic> lastVolumesMl,

    /// Currency symbol used for this keg session's cost display.
    @Default('€') String currency,
  }) = _KegSession;

  factory KegSession.fromJson(Map<String, dynamic> json) =>
      _$KegSessionFromJson(json);
}
