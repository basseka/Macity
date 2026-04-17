import 'package:flutter/material.dart';

/// Legende compacte affichee entre la carte et le carousel.
/// 5 familles = 5 couleurs, en phase avec les pins de la carte.
class ReportedEventsLegend extends StatelessWidget {
  const ReportedEventsLegend({super.key});

  static const _items = <_LegendItem>[
    _LegendItem(Color(0xFF7C3AED), 'Night'),
    _LegendItem(Color(0xFFF97316), 'Food'),
    _LegendItem(Color(0xFF0891B2), 'Culture'),
    _LegendItem(Color(0xFF10B981), 'Sport'),
    _LegendItem(Color(0xFFDC2626), 'Fiesta'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 21,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, i) {
          final it = _items[i];
          return Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: it.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: it.color.withOpacity(0.45),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                it.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
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
