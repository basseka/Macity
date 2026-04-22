import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

class DaySubcategoryCard extends StatefulWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final String? image;
  final int? count;
  final VoidCallback? onTap;
  final bool blink;
  final bool isScraped;

  const DaySubcategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.gradient,
    this.image,
    this.count,
    this.onTap,
    this.blink = false,
    this.isScraped = false,
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
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
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
                cacheWidth: 300,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(gradient: widget.gradient),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(gradient: widget.gradient),
              ),
            // Bottom dark shade (respecte le gradient mode au dessus)
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.cardShade),
              child: SizedBox.expand(),
            ),
            // Blink glow overlay (magenta au lieu de pink)
            if (widget.blink)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  final v = _glowAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.magenta.withValues(alpha: 0.9 * v),
                        width: 2.5 + 1.5 * v,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.magenta.withValues(alpha: 0.25 * v),
                          Colors.transparent,
                          AppColors.magenta.withValues(alpha: 0.15 * v),
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Scraper badge (eclair editorial)
            if (widget.isScraped)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppGradients.editorial,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.neon(
                      const Color(0xFFFBBF24),
                      blur: 6,
                      y: 1,
                    ),
                  ),
                  child: const Icon(Icons.bolt, size: 10, color: Colors.white),
                ),
              ),
            // Label + count
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.3,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                    if (widget.count != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          boxShadow: AppShadows.neon(
                            AppColors.magenta,
                            blur: 8,
                            y: 2,
                          ),
                        ),
                        child: Text(
                          '${widget.count}',
                          style: GoogleFonts.geistMono(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
