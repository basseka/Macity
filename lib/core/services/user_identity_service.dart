import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Fournit un identifiant device stable (UUID v4 genere au premier lancement).
/// Stocke dans le Keychain (iOS) / Keystore (Android) pour survivre
/// a une desinstallation/reinstallation.
/// Utilise comme user_id dans Supabase (pas d'auth Supabase).
class UserIdentityService {
  static const _key = 'user_id';
  static String? _cached;
  static const _secure = FlutterSecureStorage();

  static Future<String> getUserId() async {
    if (_cached != null) return _cached!;

    // 1. Lire depuis le stockage securise (persiste apres reinstall)
    var id = await _secure.read(key: _key);

    // 2. Migration : si absent du secure storage, migrer depuis SharedPreferences
    if (id == null) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString(_key);
      if (id != null) {
        // Copier dans le secure storage
        await _secure.write(key: _key, value: id);
      }
    }

    // 3. Premier lancement : generer un nouveau UUID
    if (id == null) {
      id = const Uuid().v4();
      await _secure.write(key: _key, value: id);
      // Aussi ecrire dans SharedPrefs pour compatibilite
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, id);
    }

    _cached = id;
    return id;
  }

  /// Replace the local user_id with an existing one (used when logging in
  /// on a new device to link to an existing Supabase profile).
  static Future<void> setUserId(String id) async {
    await _secure.write(key: _key, value: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
    _cached = id;
  }
}
