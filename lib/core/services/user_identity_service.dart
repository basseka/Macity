import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Fournit un identifiant device stable (UUID v4 genere au premier lancement).
/// Utilise comme user_id dans Supabase (pas d'auth Supabase) : toutes les
/// donnees de l'utilisateur (publications, stories, City-Miles, profil) sont
/// indexees dessus. Le perdre = perdre l'acces a ces donnees.
///
/// RESILIENCE : l'UUID est stocke en REDONDANCE dans deux emplacements aux
/// forces complementaires :
///   - `flutter_secure_storage` (Keychain iOS / Keystore Android) : survit a
///     une reinstallation, MAIS peut devenir illisible si la lib change
///     d'algorithme de chiffrement (incident 2026-07 : UUID perdu -> nouvel
///     UUID genere -> publications detachees).
///   - `SharedPreferences` (clair) : survit a un changement d'algo du secure
///     storage, mais pas a une reinstallation.
/// A chaque lecture, on lit les deux et on les RE-SYNCHRONISE : si un store a
/// ete vide, l'autre le restaure. Un nouvel UUID n'est genere que si les DEUX
/// sont vides (vrai premier lancement ou clear-data complet).
class UserIdentityService {
  static const _key = 'user_id';
  static String? _cached;
  static const _secure = FlutterSecureStorage();

  static Future<String> getUserId() async {
    if (_cached != null) return _cached!;

    // 1. Lire les deux stores (le secure peut throw si l'algo a change).
    String? secureId;
    try {
      secureId = await _secure.read(key: _key);
    } catch (_) {
      secureId = null; // illisible -> SharedPreferences prend le relais.
    }
    final prefs = await SharedPreferences.getInstance();
    final prefsId = prefs.getString(_key);

    // 2. ID existant : priorite au secure (canonique), sinon prefs.
    var id = secureId ?? prefsId;

    // 3. Nouvel UUID UNIQUEMENT si aucun des deux stores n'a d'ID.
    final isNew = id == null;
    id ??= const Uuid().v4();
    if (isNew) {
      debugPrint('[Identity] nouvel UUID genere (2 stores vides): $id');
    } else if (secureId == null || prefsId == null) {
      debugPrint('[Identity] UUID restaure depuis '
          '${secureId != null ? "secure" : "prefs"} (l\'autre store etait vide)');
    }

    // 4. Auto-reparation : garantir que les DEUX stores contiennent l'ID.
    if (secureId != id) {
      try {
        await _secure.write(key: _key, value: id);
      } catch (_) {/* best-effort : ne pas bloquer si le secure est indispo */}
    }
    if (prefsId != id) {
      await prefs.setString(_key, id);
    }

    _cached = id;
    return id;
  }

  /// Replace the local user_id with an existing one (used when logging in
  /// on a new device to link to an existing Supabase profile).
  static Future<void> setUserId(String id) async {
    try {
      await _secure.write(key: _key, value: id);
    } catch (_) {/* best-effort */}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
    _cached = id;
  }
}
