import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/pro_auth/domain/models/pro_profile.dart';

/// Session pro : tokens d'auth + profil stockes dans le secure storage natif.
///
/// Android : Keystore (hardware-backed quand dispo)
/// iOS     : Keychain
///
/// Migration auto depuis SharedPreferences : les anciennes installations qui
/// avaient les tokens en clair sont migrees vers secure storage au premier
/// read. La migration est one-shot (flag `_keyMigratedV1`).
class ProSessionService {
  // Cle de flag de migration — stockee dans secure storage une fois la
  // migration effectuee pour ne pas recommencer a chaque read.
  static const _keyMigratedV1 = 'pro_session_migrated_v1';

  // Cles existantes (gardees identiques, meme valeur qu'en SharedPreferences)
  static const _keyIsProConnected = 'is_pro_connected';
  static const _keyProProfile = 'pro_profile';
  static const _keyAccessToken = 'pro_access_token';
  static const _keyRefreshToken = 'pro_refresh_token';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _migrationChecked = false;

  /// Migre les anciennes cles SharedPreferences vers secure storage (one-shot).
  Future<void> _migrateIfNeeded() async {
    if (_migrationChecked) return;
    _migrationChecked = true;
    try {
      final already = await _storage.read(key: _keyMigratedV1);
      if (already == 'true') return;

      final prefs = await SharedPreferences.getInstance();
      final legacyConnected = prefs.getBool(_keyIsProConnected);
      final legacyProfile = prefs.getString(_keyProProfile);
      final legacyAccess = prefs.getString(_keyAccessToken);
      final legacyRefresh = prefs.getString(_keyRefreshToken);

      if (legacyConnected == true && legacyAccess != null) {
        await _storage.write(key: _keyIsProConnected, value: 'true');
        if (legacyProfile != null) {
          await _storage.write(key: _keyProProfile, value: legacyProfile);
        }
        await _storage.write(key: _keyAccessToken, value: legacyAccess);
        if (legacyRefresh != null) {
          await _storage.write(key: _keyRefreshToken, value: legacyRefresh);
        }
        debugPrint('[ProSession] migrated legacy session to secure storage');
      }

      // Nettoie les anciennes cles et marque la migration faite
      await prefs.remove(_keyIsProConnected);
      await prefs.remove(_keyProProfile);
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await _storage.write(key: _keyMigratedV1, value: 'true');
    } catch (e) {
      debugPrint('[ProSession] migration error: $e');
    }
  }

  Future<void> saveSession({
    required ProProfile profile,
    required String accessToken,
    required String refreshToken,
  }) async {
    await _migrateIfNeeded();
    try {
      await _storage.write(key: _keyIsProConnected, value: 'true');
      await _storage.write(
        key: _keyProProfile,
        value: jsonEncode(profile.toJson()),
      );
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      debugPrint('[ProSession] saveSession OK nom=${profile.nom}');
    } catch (e) {
      debugPrint('[ProSession] saveSession FAILED: $e');
      rethrow;
    }
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _migrateIfNeeded();
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> updateProfile(ProProfile profile) async {
    await _migrateIfNeeded();
    await _storage.write(
      key: _keyProProfile,
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<ProProfile?> getProfile() async {
    await _migrateIfNeeded();
    final json = await _storage.read(key: _keyProProfile);
    if (json == null) return null;
    return ProProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<String?> getAccessToken() async {
    await _migrateIfNeeded();
    return _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    await _migrateIfNeeded();
    return _storage.read(key: _keyRefreshToken);
  }

  Future<bool> isConnected() async {
    await _migrateIfNeeded();
    final v = await _storage.read(key: _keyIsProConnected);
    return v == 'true';
  }

  Future<void> clearSession() async {
    await _migrateIfNeeded();
    await _storage.delete(key: _keyIsProConnected);
    await _storage.delete(key: _keyProProfile);
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
