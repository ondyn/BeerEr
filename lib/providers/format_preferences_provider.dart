import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/providers/user_providers.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'format_preferences_provider.g.dart';

/// Provides the current user's formatting preferences.
///
/// Falls back to defaults when the user is not signed in or has
/// not configured any preferences yet.
@riverpod
FormatPreferences formatPreferences(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;
  if (user == null) return const FormatPreferences();

  final appUserAsync = ref.watch(watchCurrentUserProvider(user.uid));
  final appUser = appUserAsync.asData?.value;
  if (appUser == null) return const FormatPreferences();

  return FormatPreferences.fromMap(appUser.preferences);
}
