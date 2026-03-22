import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// Provides the current locale based on the user's Firestore preferences.
/// Falls back to English when no preference is set or user is not signed in.
@riverpod
Locale appLocale(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;
  if (user == null) return const Locale('en');

  final appUserAsync = ref.watch(watchCurrentUserProvider(user.uid));
  final appUser = appUserAsync.asData?.value;
  if (appUser == null) return const Locale('en');

  final langCode = appUser.preferences['language'] as String? ?? 'en';
  if (['en', 'cs', 'de'].contains(langCode)) {
    return Locale(langCode);
  }
  return const Locale('en');
}
