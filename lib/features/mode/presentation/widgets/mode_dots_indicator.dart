import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/app_constants.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

class ModeDotsIndicator extends ConsumerWidget {
  const ModeDotsIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeIndex = ref.watch(modeIndexProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        AppConstants.modeOrder.length,
        (index) {
          final isActive = index == modeIndex;
          final dotColor = isActive
              ? modeTheme.primaryColor
              : Colors.grey.shade400;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 12 : 8,
            height: isActive ? 12 : 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}
