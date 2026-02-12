import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/constants/app_constants.dart';

class CityNotifier extends StateNotifier<String> {
  CityNotifier() : super(AppConstants.defaultCity) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(AppConstants.prefSelectedCity) ??
        AppConstants.defaultCity;
  }

  Future<void> setCity(String city) async {
    state = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefSelectedCity, city);
  }
}

final selectedCityProvider = StateNotifierProvider<CityNotifier, String>(
  (ref) => CityNotifier(),
);
