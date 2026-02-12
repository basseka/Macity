import 'package:flutter/material.dart';

class SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double velocityThreshold;

  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.velocityThreshold = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;

        if (velocity.abs() < velocityThreshold) return;

        if (velocity < 0) {
          // Swipe left -> next mode
          onSwipeLeft?.call();
        } else {
          // Swipe right -> previous mode
          onSwipeRight?.call();
        }
      },
      child: child,
    );
  }
}
