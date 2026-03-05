import 'package:freezed_annotation/freezed_annotation.dart';

part 'joint_account.freezed.dart';
part 'joint_account.g.dart';

@freezed
class JointAccount with _$JointAccount {
  const factory JointAccount({
    required String id,
    required String sessionId,
    required String groupName,
    @Default([]) List<String> memberUserIds,
  }) = _JointAccount;

  factory JointAccount.fromJson(Map<String, dynamic> json) =>
      _$JointAccountFromJson(json);
}
