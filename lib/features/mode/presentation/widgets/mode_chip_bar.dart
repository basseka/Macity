import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

class ModeChipBar extends ConsumerWidget {
  const ModeChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: modeTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: AppMode.order.map((mode) {
          final isSelected = mode.name == currentMode;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: ChoiceChip(
              label: Text(mode.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(currentModeProvider.notifier).setMode(mode.name);
                context.go(mode.routePath);
              },
              selectedColor: modeTheme.chipBgColor,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected
                    ? modeTheme.chipTextColor
                    : Colors.grey.shade600,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? modeTheme.chipStrokeColor
                    : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}
