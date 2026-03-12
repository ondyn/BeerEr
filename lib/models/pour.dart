import 'package:freezed_annotation/freezed_annotation.dart';

part 'pour.freezed.dart';
part 'pour.g.dart';

@freezed
abstract class Pour with _$Pour {
  const factory Pour({
    required String id,
    required String sessionId,
    required String userId,
    required String pouredById,
    required double volumeMl,
    required DateTime timestamp,
    @Default(false) bool undone,
  }) = _Pour;

  factory Pour.fromJson(Map<String, dynamic> json) => _$PourFromJson(json);
}
