class AppConstants {
  AppConstants._();

  // Modes
  static const String modeDay = 'day';
  static const String modeSport = 'sport';
  static const String modeCulture = 'culture';
  static const String modeFamily = 'family';
  static const String modeFood = 'food';
  static const String modeGaming = 'gaming';
  static const String modeNight = 'night';

  static const List<String> modeOrder = [modeDay, modeSport, modeCulture, modeFamily, modeFood, modeGaming, modeNight];

  // Preferences
  static const String prefsName = 'onyva_prefs';
  static const String prefCurrentMode = 'current_mode';
  static const String prefSelectedCity = 'selected_city';

  // Results
  static const int maxResults = 50;
  static const int eventPageSize = 100;
  static const int eventWindowDays = 365;

  // Colors
  static const int colorInactiveBg = 0x1A000000;
  static const int colorInactiveText = 0xFF666666;

  // Database
  static const String databaseName = 'commerces_db';
  static const int databaseVersion = 4;

  // Cache
  static const int osmCacheDays = 7;

  // Default city
  static const String defaultCity = 'Toulouse';
}
