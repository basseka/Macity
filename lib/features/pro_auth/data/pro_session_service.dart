import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/pro_auth/domain/models/pro_profile.dart';

class ProSessionService {
  static const _keyIsProConnected = 'is_pro_connected';
  static const _keyProProfile = 'pro_profile';
  static const _keyAccessToken = 'pro_access_token';
  static const _keyRefreshToken = 'pro_refresh_token';

  Future<void> saveSession({
    required ProProfile profile,
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsProConnected, true);
    await prefs.setString(_keyProProfile, jsonEncode(profile.toJson()));
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<void> updateProfile(ProProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProProfile, jsonEncode(profile.toJson()));
  }

  Future<ProProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyProProfile);
    if (json == null) return null;
    return ProProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsProConnected) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsProConnected, false);
    await prefs.remove(_keyProProfile);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }
}
