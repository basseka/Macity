import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Fournit un identifiant device stable (UUID v4 genere au premier lancement).
/// Utilise comme user_id dans Supabase (pas d'auth Supabase).
class UserIdentityService {
  static const _key = 'user_id';
  static String? _cached;

  static Future<String> getUserId() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}
