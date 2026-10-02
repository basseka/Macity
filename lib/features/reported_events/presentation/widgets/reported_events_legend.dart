import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Legende compacte affichee entre la carte et le carousel.
/// 5 familles = 5 couleurs, en phase avec les pins de la carte.
class ReportedEventsLegend extends StatelessWidget {
  /// Posee sur la carte plein ecran (MapLive) : texte blanc plus gros,
  /// une seule ligne centree qui se reduit pour tenir dans la largeur.
  final bool onMap;

  const ReportedEventsLegend({super.key, this.onMap = false});

  static const _items = <_LegendItem>[
    _LegendItem(AppColors.catNight, 'Night'),
    _LegendItem(AppColors.catFood, 'Food'),
    _LegendItem(AppColors.catCult, 'Culture'),
    _LegendItem(AppColors.catSport, 'Sport'),
    _LegendItem(AppColors.catFiesta, 'Fiesta'),
  ];

  Widget _dot(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (onMap) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              _dot(_items[i].color, 11),
              const SizedBox(width: 6),
              Text(
                _items[i].label,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: 18,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = _items[i];
          return Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: it.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: it.color.withValues(alpha: 0.55),
                      blurRadius: 5,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                it.label.toUpperCase(),
                style: GoogleFonts.geistMono(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: AppColors.textDim,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);
}
