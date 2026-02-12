import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

final modeThemeProvider = Provider<ModeTheme>((ref) {
  final mode = ref.watch(currentModeProvider);
  return ModeTheme.fromModeName(mode);
});
