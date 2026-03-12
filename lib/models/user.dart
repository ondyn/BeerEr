import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String nickname,
    @Default('') String email,
    @Default(0.0) double weightKg,
    @Default(0) int age,
    @Default('male') String gender,
    @Default('email') String authProvider,
    @Default({}) Map<String, dynamic> preferences,
  }) = _AppUser;

  const AppUser._();

  /// Whether other users are allowed to pour beer for this user.
  /// Defaults to true when the preference has not been explicitly set.
  bool get allowPourForMe =>
      preferences['allow_pour_for_me'] as bool? ?? true;

  /// Returns nickname if set, otherwise falls back to email, then a
  /// shortened user id so the chip is never blank.
  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (email.trim().isNotEmpty) return email.trim();
    // Last resort: first 6 chars of the uid
    return id.length > 6 ? id.substring(0, 6) : id;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
