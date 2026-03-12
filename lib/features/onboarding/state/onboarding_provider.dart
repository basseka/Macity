import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';

const _onboardingDoneKey = 'onboarding_done';

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingDoneKey) ?? false;
});

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingDoneKey, true);
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
