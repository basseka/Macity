import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Pin de carte anime : cercle central + ring expansif qui pulse.
class PulsingMapPin extends StatefulWidget {
  final Color color;
  final String label;
  const PulsingMapPin({super.key, required this.color, required this.label});

  @override
  State<PulsingMapPin> createState() => _PulsingMapPinState();
}

class _PulsingMapPinState extends State<PulsingMapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final p = _c.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding ring
            Container(
              width: 34 + p * 28,
              height: 34 + p * 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity((1 - p).clamp(0, 1)),
                  width: 2,
                ),
              ),
            ),
            // Core pin
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                border: Border.all(color: AppColors.bg, width: 2.5),
                boxShadow: AppShadows.pinGlow(widget.color),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
