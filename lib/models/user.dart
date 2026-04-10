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
    int? avatarIcon,

    /// Whether the account has been soft-deleted. Personal data is wiped but
    /// the record is kept so pours/sessions remain consistent for others.
    @Default(false) bool suspended,

    /// ISO-8601 timestamp when the account was soft-deleted, or null if active.
    String? deletedAt,
  }) = _AppUser;

  const AppUser._();

  /// Whether other users are allowed to pour beer for this user.
  /// Defaults to true when the preference has not been explicitly set.
  bool get allowPourForMe =>
      preferences['allow_pour_for_me'] as bool? ?? true;

  /// Returns nickname if set, otherwise falls back to email, then a
  /// shortened user id so the chip is never blank.
  /// Suspended accounts always show 'Deleted User'.
  String get displayName {
    if (suspended) return 'Deleted User';
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (email.trim().isNotEmpty) return email.trim();
    // Last resort: first 6 chars of the uid
    return id.length > 6 ? id.substring(0, 6) : id;
  }

  static Map<String, dynamic> _normaliseJson(Map<String, dynamic> json) {
    return <String, dynamic>{
      ...json,
      'id': json['id'] is String ? json['id'] : '',
      'nickname': json['nickname'] is String ? json['nickname'] : '',
      'email': json['email'] is String ? json['email'] : '',
      'gender': json['gender'] is String ? json['gender'] : 'male',
      'auth_provider':
          json['auth_provider'] is String ? json['auth_provider'] : 'email',
      'preferences': json['preferences'] is Map<String, dynamic>
          ? json['preferences']
          : <String, dynamic>{},
      'deleted_at': json['deleted_at'] is String ? json['deleted_at'] : null,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(_normaliseJson(json));
}
