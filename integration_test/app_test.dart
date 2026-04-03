/// Master integration test runner.
///
/// Imports all individual integration test files so they can be run
/// in a single invocation:
///
/// ```zsh
/// .fvm/flutter_sdk/bin/flutter test integration_test/app_test.dart
/// ```
library;

import 'account_lifecycle_test.dart' as account_lifecycle;
import 'join_session_test.dart' as join_session;
import 'joint_account_test.dart' as joint_account;
import 'keg_done_flow_test.dart' as keg_done_flow;
import 'keg_lifecycle_test.dart' as keg_lifecycle;

void main() {
  keg_lifecycle.main();
  join_session.main();
  joint_account.main();
  keg_done_flow.main();
  account_lifecycle.main();
}
