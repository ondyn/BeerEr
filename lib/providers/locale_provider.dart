import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

const _kLocalLanguageKey = 'app_language';
const _supportedLanguages = ['en', 'cs', 'de'];

/// Pre-auth locale override. Set by the language picker on the welcome/sign-in
/// screens and persisted to SharedPreferences. When the user signs in, the
/// Firestore preference takes precedence.
@riverpod
class PreAuthLocale extends _$PreAuthLocale {
  @override
  String? build() => null;

  void set(String? langCode) {
    state = langCode;
  }
}

/// Loads the locally persisted language code from SharedPreferences.
/// Called once at app start to seed [preAuthLocaleProvider].
Future<String?> loadLocalLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kLocalLanguageKey);
}

/// Persists a language code to SharedPreferences so it survives app restarts.
Future<void> saveLocalLanguage(String langCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLocalLanguageKey, langCode);
}

/// Provides the current locale based on the user's Firestore preferences.
/// Falls back to the pre-auth locale (SharedPreferences) when no user is
/// signed in, and ultimately defaults to English.
@riverpod
Locale appLocale(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;

  if (user != null) {
    final appUserAsync = ref.watch(watchCurrentUserProvider(user.uid));
    final appUser = appUserAsync.asData?.value;
    if (appUser != null) {
      final langCode = appUser.preferences['language'] as String? ?? 'en';
      if (_supportedLanguages.contains(langCode)) {
        return Locale(langCode);
      }
    }
  }

  // Fall back to locally stored language (pre-auth selection).
  final preAuth = ref.watch(preAuthLocaleProvider);
  if (preAuth != null && _supportedLanguages.contains(preAuth)) {
    return Locale(preAuth);
  }

  return const Locale('en');
}
