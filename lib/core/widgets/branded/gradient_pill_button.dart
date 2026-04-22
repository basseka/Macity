import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// CTA pill avec degrade primaire + point pulse blanc.
/// Usage type : "Live Notif".
class GradientPillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool pulseDot;
  const GradientPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.pulseDot = true,
  });

  @override
  State<GradientPillButton> createState() => _GradientPillButtonState();
}

class _GradientPillButtonState extends State<GradientPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: AppShadows.neon(AppColors.magenta, blur: 16, y: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.pulseDot) ...[
              FadeTransition(
                opacity: Tween(begin: 0.6, end: 1.0).animate(_c),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
