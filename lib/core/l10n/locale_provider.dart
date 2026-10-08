import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langues proposees dans l'app. Le francais est la langue de reference :
/// une cle non traduite retombe sur le francais (cf. l10n.yaml).
const kAppLanguages = <String, String>{
  'fr': 'Français',
  'en': 'English',
  'es': 'Español',
};

const _localeKey = 'app_locale';

/// Langue choisie a la main, lue au demarrage (cf. main.dart) pour que le
/// premier ecran s'affiche directement dans la bonne langue.
String? _savedLanguage;

Future<void> initLocaleState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    _savedLanguage = kAppLanguages.containsKey(code) ? code : null;
  } catch (_) {
    _savedLanguage = null;
  }
}

/// null = automatique (langue du telephone), sinon 'fr' / 'en' / 'es'.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier()
      : super(_savedLanguage == null ? null : Locale(_savedLanguage!));

  Future<void> setLanguage(String? code) async {
    state = code == null ? null : Locale(code);
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, code);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) => LocaleNotifier());

/// Mode automatique : premiere langue du telephone geree par l'app, sinon
/// anglais (visiteur etranger).
Locale resolveAppLocale(List<Locale>? deviceLocales) {
  for (final l in deviceLocales ?? const <Locale>[]) {
    if (kAppLanguages.containsKey(l.languageCode)) return Locale(l.languageCode);
  }
  return const Locale('en');
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
