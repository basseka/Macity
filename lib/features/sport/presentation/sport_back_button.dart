import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';

/// Bouton retour reutilisable pour les sous-ecrans sport.
class SportBackButton extends ConsumerWidget {
  final String label;
  final VoidCallback onBack;
  final String? title;
  final Widget? leading;

  const SportBackButton({
    super.key,
    required this.label,
    required this.onBack,
    this.title,
    this.leading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Text(
              title ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: modeTheme.primaryDarkColor,
              ),
            ),
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: modeTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
