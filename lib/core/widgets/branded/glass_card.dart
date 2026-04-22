import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Container "glass" (blur + surface translucide).
/// Usage : tab bar floating, legende map, panneaux flottants.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  const GlassCard({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.blur = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.line),
          ),
          child: child,
        ),
      ),
    );
  }
}
