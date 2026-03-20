import 'package:shared_preferences/shared_preferences.dart';

/// Persists user profile data (weight, age, gender) on the device.
///
/// Values are loaded at app start and restored when the user signs in,
/// until the user logs out or deletes their account.
class LocalProfile {
  LocalProfile._();
  static final LocalProfile instance = LocalProfile._();

  static const _keyWeight = 'profile_weight_kg';
  static const _keyAge = 'profile_age';
  static const _keyGender = 'profile_gender';

  /// Saves profile data locally.
  Future<void> save({
    required double weightKg,
    required int age,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWeight, weightKg);
    await prefs.setInt(_keyAge, age);
    await prefs.setString(_keyGender, gender);
  }

  /// Loads locally persisted profile data.
  ///
  /// Returns `null` values when no data has been saved.
  Future<({double weightKg, int age, String gender})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      weightKg: prefs.getDouble(_keyWeight) ?? 0,
      age: prefs.getInt(_keyAge) ?? 0,
      gender: prefs.getString(_keyGender) ?? 'male',
    );
  }

  /// Clears locally persisted profile data (e.g. on logout).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWeight);
    await prefs.remove(_keyAge);
    await prefs.remove(_keyGender);
  }
}
