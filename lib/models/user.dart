import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String nickname,
    @Default(0.0) double weightKg,
    @Default(0) int age,
    @Default('male') String gender,
    @Default('email') String authProvider,
    @Default({}) Map<String, dynamic> preferences,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
