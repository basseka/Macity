import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

class ModeHeader extends ConsumerWidget {
  const ModeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final appMode = AppMode.fromName(currentMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: modeTheme.primaryDarkColor,
              size: 22,
            ),
            tooltip: 'Retour',
          ),
          const SizedBox(width: 4),
          Text(
            '${appMode.emoji} ${appMode.label}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modeTheme.primaryDarkColor,
            ),
          ),
        ],
      ),
    );
  }
}
