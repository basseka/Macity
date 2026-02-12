import 'package:flutter/material.dart';

class DaySubcategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final String? image;
  final int? count;
  final VoidCallback? onTap;

  const DaySubcategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.gradient,
    this.image,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: image or gradient
            if (image != null)
              Image.asset(
                image!,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(gradient: gradient),
              ),
            // Dark overlay for text readability
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            // Label + count
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: [
                          Shadow(blurRadius: 3, color: Colors.black54),
                        ],
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black45),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
