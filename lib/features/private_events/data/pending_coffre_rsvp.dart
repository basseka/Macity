import 'package:shared_preferences/shared_preferences.dart';

/// RSVP "Je viens" mis en attente le temps de l'inscription : l'invite sans
/// profil est envoye sur l'onboarding, puis ramene sur le coffre qui se
/// rouvre et confirme sa venue automatiquement.
class PendingCoffreRsvp {
  static const _key = 'pending_coffre_rsvp';
  static const _maxAge = Duration(hours: 24);

  static Future<void> save({
    required String token,
    required String passcode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_key, '$token|$passcode|$ts');
  }

  /// Lit sans consommer. Null si absent ou plus vieux que 24h.
  static Future<({String token, String passcode})?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    final parts = prefs.getString(_key)?.split('|');
    if (parts == null || parts.length != 3) return null;
    final ts = int.tryParse(parts[2]);
    if (ts == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
            _maxAge) {
      await clear();
      return null;
    }
    return (token: parts[0], passcode: parts[1]);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Route a ouvrir apres inscription/connexion : le coffre en attente s'il y
  /// en a un, sinon l'accueil.
  static Future<String> postAuthRoute() async {
    final pending = await peek();
    return pending != null ? '/coffre/${pending.token}' : '/home';
  }
}
