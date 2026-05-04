import 'package:flutter/material.dart';

/// Affichage de note sous forme d'etoiles (1 a 5).
///
/// - `interactive: false` (defaut) : affiche [value] etoiles pleines/demi-pleines
///   (supporte les decimales pour la moyenne, ex 4.3).
/// - `interactive: true` : tap sur une etoile pour selectionner. Appelle
///   [onChanged] avec un int 1..5. La valeur affichee suit [value].
class StarRating extends StatelessWidget {
  final double value;
  final int max;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 16,
    this.filledColor = const Color(0xFFFFC107), // amber
    this.emptyColor = const Color(0xFF555555),
    this.interactive = false,
    this.onChanged,
  }) : assert(!interactive || onChanged != null,
            'interactive=true requires onChanged');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final pos = i + 1;
        final IconData icon;
        if (value >= pos) {
          icon = Icons.star_rounded;
        } else if (value >= pos - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        final star = Icon(
          icon,
          size: size,
          color: value >= pos - 0.5 ? filledColor : emptyColor,
        );
        if (!interactive) return star;
        return GestureDetector(
          onTap: () => onChanged!(pos),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}
