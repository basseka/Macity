import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';

const _onboardingDoneKey = 'onboarding_done';

/// Verrou d'accès à l'app : passe à true uniquement après une inscription OU
/// une connexion réussie (email + téléphone fournis). Tant qu'il est false,
/// le routeur renvoie sur l'onboarding (cf. gating dans app_router.dart).
/// Distinct de `onboarding_done` pour re-verrouiller les anciens utilisateurs
/// qui avaient « passé » l'étape avant que l'inscription devienne obligatoire.
const _userRegisteredKey = 'user_registered';

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingDoneKey) ?? false;
});

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingDoneKey, true);
}

/// Marque l'utilisateur comme inscrit (email + téléphone enregistrés).
Future<void> markRegistered() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_userRegisteredKey, true);
}

final userProfileServiceProvider = Provider((_) => UserProfileService());

/// Preferences d'activites de l'utilisateur (depuis Supabase).
/// Retourne une liste vide si pas de profil (= pas de filtre, tout afficher).
final userPreferencesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null || profile['preferences'] == null) return [];
    return (profile['preferences'] as List).cast<String>();
  } catch (_) {
    return [];
  }
});

/// Prenom de l'utilisateur (depuis Supabase).
final userPrenomProvider = FutureProvider<String>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null) return '';
    return (profile['prenom'] as String?) ?? '';
  } catch (_) {
    return '';
  }
});

/// URL de la photo de profil de l'utilisateur (depuis Supabase).
final userAvatarUrlProvider = FutureProvider<String?>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null) return null;
    final url = profile['avatar_url'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  } catch (_) {
    return null;
  }
});

/// Ville de l'utilisateur (depuis Supabase).
final userVilleProvider = FutureProvider<String>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null) return '';
    return (profile['ville'] as String?) ?? '';
  } catch (_) {
    return '';
  }
});

/// Preferences detaillees (sous-interets) de l'utilisateur.
/// Format: ["mode:tag", ...] ex: ["sport:football", "day:festival"]
final userDetailedPreferencesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null || profile['preferences_detailed'] == null) return [];
    return (profile['preferences_detailed'] as List).cast<String>();
  } catch (_) {
    return [];
  }
});

/// Villes pour lesquelles l'utilisateur recoit les notifications mairie.
final userVillesNotificationsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final profile = await UserProfileService().fetchProfile();
    if (profile == null) return [];
    final villes = profile['villes_notifications'];
    if (villes == null) return [];
    return (villes as List).cast<String>();
  } catch (_) {
    return [];
  }
});
