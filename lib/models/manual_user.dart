import 'package:freezed_annotation/freezed_annotation.dart';

part 'manual_user.freezed.dart';
part 'manual_user.g.dart';

/// A lightweight guest participant created by the keg creator for people
/// who don't have the app installed.
///
/// Stored as `kegSessions/{sessionId}/manualUsers/{id}` in Firestore.
/// Pours reference the manual user's [id] as `user_id`.
///
/// When a real user joins and merges with a manual user, all pours with
/// `user_id == manualUser.id` are reassigned to the real user.
@freezed
abstract class ManualUser with _$ManualUser {
  const factory ManualUser({
    required String id,
    required String sessionId,
    required String nickname,
  }) = _ManualUser;

  factory ManualUser.fromJson(Map<String, dynamic> json) =>
      _$ManualUserFromJson(json);
}
