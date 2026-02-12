import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/constants/app_constants.dart';

class ModeNotifier extends StateNotifier<String> {
  bool _manuallySet = false;

  ModeNotifier() : super(AppConstants.modeDay) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_manuallySet) return;
    state = prefs.getString(AppConstants.prefCurrentMode) ?? AppConstants.modeDay;
  }

  Future<void> setMode(String mode) async {
    _manuallySet = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrentMode, mode);
  }

  void nextMode() {
    final currentIndex = AppConstants.modeOrder.indexOf(state);
    final nextIndex = (currentIndex + 1) % AppConstants.modeOrder.length;
    setMode(AppConstants.modeOrder[nextIndex]);
  }

  void previousMode() {
    final currentIndex = AppConstants.modeOrder.indexOf(state);
    final prevIndex =
        (currentIndex - 1 + AppConstants.modeOrder.length) % AppConstants.modeOrder.length;
    setMode(AppConstants.modeOrder[prevIndex]);
  }
}

final currentModeProvider = StateNotifierProvider<ModeNotifier, String>(
  (ref) => ModeNotifier(),
);

final modeIndexProvider = Provider<int>((ref) {
  final mode = ref.watch(currentModeProvider);
  return AppConstants.modeOrder.indexOf(mode);
});
