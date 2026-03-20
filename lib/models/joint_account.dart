import 'package:freezed_annotation/freezed_annotation.dart';

part 'joint_account.freezed.dart';
part 'joint_account.g.dart';

@freezed
abstract class JointAccount with _$JointAccount {
  const factory JointAccount({
    required String id,
    required String sessionId,
    required String groupName,
    required String creatorId,
    @Default([]) List<String> memberUserIds,
    int? avatarIcon,
  }) = _JointAccount;

  factory JointAccount.fromJson(Map<String, dynamic> json) =>
      _$JointAccountFromJson(json);
}
