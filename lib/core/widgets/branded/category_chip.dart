import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Chip de categorie (etats selected + idle).
/// Selected : degrade primaire + shadow neon, texte blanc.
/// Idle : surface + border line, texte textDim.
class CategoryChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool selected;
  final VoidCallback? onTap;
  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.line,
          ),
          boxShadow: selected
              ? AppShadows.neon(AppColors.magenta, blur: 20, y: 8)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 7)],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textDim,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
