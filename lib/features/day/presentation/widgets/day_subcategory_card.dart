import 'package:flutter/material.dart';

class DaySubcategoryCard extends StatefulWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final String? image;
  final int? count;
  final VoidCallback? onTap;
  final bool blink;

  const DaySubcategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.gradient,
    this.image,
    this.count,
    this.onTap,
    this.blink = false,
  });

  @override
  State<DaySubcategoryCard> createState() => _DaySubcategoryCardState();
}

class _DaySubcategoryCardState extends State<DaySubcategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.blink) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DaySubcategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blink && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.blink && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: image or gradient
            if (widget.image != null)
              Image.asset(
                widget.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
              )
            else
              Container(
                decoration: BoxDecoration(gradient: widget.gradient),
              ),
            // Dark overlay for text readability
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            // Blink glow overlay
            if (widget.blink)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  final v = _glowAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.9 * v),
                        width: 2.5 + 1.5 * v,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.pink.withValues(alpha: 0.25 * v),
                          Colors.transparent,
                          Colors.pink.withValues(alpha: 0.15 * v),
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Label + count
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
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
                    if (widget.count != null) ...[
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
                          '${widget.count}',
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
