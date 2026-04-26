import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Chip de filtre pill (radius 999). Handoff coherence v1.0 :
/// - Actif : gradient magenta-deep -> pink avec ombre douce, texte blanc bold
/// - Idle : bordure 1.5px stroke, texte textDim
class EditorialFilterChip extends StatelessWidget {
  final String label;
  final bool active;

  /// Conserve pour compat — non utilise dans le nouveau design (active = gradient
  /// magenta partage). On garde l'API pour ne pas casser les call sites.
  final Color accent;
  final VoidCallback onTap;

  const EditorialFilterChip({
    super.key,
    required this.label,
    required this.active,
    this.accent = EditorialColors.magenta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? EditorialGradients.cta : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(EditorialRadius.pill),
          border: active
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: EditorialColors.magentaDeep.withValues(alpha: 0.6),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: EditorialText.chip(
            color: active ? Colors.white : EditorialColors.textDim,
          ).copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Rangee horizontale scrollable de chips. Pratique pour le pattern standard.
class EditorialFilterChipBar extends StatelessWidget {
  final List<String> labels;
  final String activeLabel;

  /// Conserve pour compat — la couleur active est partagee (gradient magenta).
  final Color accent;
  final ValueChanged<String> onChanged;

  const EditorialFilterChipBar({
    super.key,
    required this.labels,
    required this.activeLabel,
    this.accent = EditorialColors.magenta,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EditorialSpacing.screen),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: EditorialSpacing.sm),
        itemBuilder: (context, i) {
          final label = labels[i];
          return EditorialFilterChip(
            label: label,
            active: label == activeLabel,
            accent: accent,
            onTap: () => onChanged(label),
          );
        },
      ),
    );
  }
}
