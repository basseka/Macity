import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/constants/app_constants.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';

class CityNotifier extends StateNotifier<String> {
  CityNotifier() : super(AppConstants.defaultCity) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(AppConstants.prefSelectedCity) ??
        AppConstants.defaultCity;
  }

  /// [updateProfile] à false pour un changement automatique (GPS) : un
  /// déplacement ne doit pas réécrire la ville du profil (digests, notifs).
  Future<void> setCity(String city, {bool updateProfile = true}) async {
    state = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefSelectedCity, city);
    if (updateProfile) {
      UserProfileService().updateVille(city).catchError((_) {});
    }
  }
}

final selectedCityProvider = StateNotifierProvider<CityNotifier, String>(
  (ref) => CityNotifier(),
);
