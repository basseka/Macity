import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Data helpers ───────────────────────────────────────────────

class _StarData {
  final double x, y, size, delay, maxOpacity;
  const _StarData(this.x, this.y, this.size, this.delay, this.maxOpacity);
}

class _BuildingData {
  final double x, width, height;
  final bool hasSpire;
  final bool hasDome;
  const _BuildingData(this.x, this.width, this.height,
      {this.hasSpire = false, this.hasDome = false,});
}

class _IconInfo {
  final IconData icon;
  final String label;
  const _IconInfo(this.icon, this.label);
}

// ─── Splash Screen ──────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase 1 — Skyline rises
  late final Animation<double> _skylineSlide;
  late final Animation<double> _skylineOpacity;

  // Phase 2 — City lights
  late final Animation<double> _lightsProgress;

  // Phase 3 — Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Phase 4 — Title + tagline
  late final Animation<double> _titleOpacity;
  late final Animation<double> _taglineOpacity;

  // Phase 5 — Icons (staggered)
  late final List<Animation<double>> _iconAnimations;

  // Pre-computed stars
  static final _stars = List.generate(30, (i) {
    final r = math.Random(i * 42);
    return _StarData(
      r.nextDouble(),
      r.nextDouble() * 0.45,
      1.0 + r.nextDouble() * 2.0,
      r.nextDouble() * 0.20,
      0.25 + r.nextDouble() * 0.50,
    );
  });

  static const _icons = <_IconInfo>[
    _IconInfo(Icons.music_note_rounded, 'Soirées'),
    _IconInfo(Icons.theater_comedy_rounded, 'Culture'),
    _IconInfo(Icons.mic_rounded, 'Concert'),
    _IconInfo(Icons.restaurant_rounded, 'Resto'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // ── Phase 1 : Skyline (0 %–22 %) ──
    _skylineSlide = Tween(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
      ),
    );
    _skylineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.15, curve: Curves.easeIn),
      ),
    );

    // ── Phase 2 : Lights (10 %–50 %) ──
    _lightsProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.50, curve: Curves.easeInOut),
      ),
    );

    // ── Phase 3 : Logo (20 %–42 %) ──
    _logoScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.42, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.32, curve: Curves.easeIn),
      ),
    );

    // ── Phase 4 : Title + tagline (35 %–60 %) ──
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.48, curve: Curves.easeIn),
      ),
    );
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.60, curve: Curves.easeIn),
      ),
    );

    // ── Phase 5 : Icons staggered (55 %–82 %) ──
    _iconAnimations = List.generate(4, (i) {
      final start = 0.55 + i * 0.06;
      return Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.14, curve: Curves.easeOutBack),
        ),
      );
    });

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 5600), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: screen.width,
            height: screen.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D0618),
                  Color(0xFF1A0A2E),
                  Color(0xFF2D1245),
                  Color(0xFF4A1259),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // ── Stars ──
                for (int i = 0; i < _stars.length; i++)
                  _buildStar(i, screen),

                // ── Skyline (compact, bottom) ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _skylineSlide.value,
                  child: Opacity(
                    opacity: _skylineOpacity.value,
                    child: SizedBox(
                      height: screen.height * 0.22,
                      child: CustomPaint(
                        size: Size(screen.width, screen.height * 0.22),
                        painter: _SkylinePainter(
                          lightsProgress: _lightsProgress.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Ground glow ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 30,
                  child: Opacity(
                    opacity: _lightsProgress.value * 0.3,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00FFD700), Color(0x33FFD700)],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Central content ──
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Logo P
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE91E8C)
                                        .withValues(alpha: 0.45 * _logoOpacity.value),
                                    blurRadius: 25,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF7B2D8E)
                                        .withValues(alpha: 0.25 * _logoOpacity.value),
                                    blurRadius: 40,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // App name
                        Opacity(
                          opacity: _titleOpacity.value,
                          child: const Text(
                            'MaCity',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline — bien visible
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'Tout ce qui se passe',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'dans votre ville',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFFE91E8C),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 1),

                        // ── Icons row ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (i) {
                              return _buildIconBadge(
                                _icons[i],
                                _iconAnimations[i].value,
                              );
                            }),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Star ──
  Widget _buildStar(int index, Size screen) {
    final star = _stars[index];
    final opacity =
        ((_controller.value - star.delay) / 0.25).clamp(0.0, 1.0) *
            star.maxOpacity;

    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned(
      left: star.x * screen.width,
      top: star.y * screen.height,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: star.size,
          height: star.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: star.size * 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Icon badge (Material icon + label) ──
  Widget _buildIconBadge(_IconInfo info, double progress) {
    if (progress <= 0) return const SizedBox(width: 64);

    final clamped = progress.clamp(0.0, 1.0);

    return Transform.scale(
      scale: clamped,
      child: Opacity(
        opacity: clamped,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFFE91E8C).withValues(alpha: 0.3 * clamped),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(info.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skyline CustomPainter ──────────────────────────────────────

class _SkylinePainter extends CustomPainter {
  final double lightsProgress;

  _SkylinePainter({required this.lightsProgress});

  static const _buildings = <_BuildingData>[
    _BuildingData(0.00, 0.06, 0.30),
    _BuildingData(0.06, 0.04, 0.45),
    _BuildingData(0.10, 0.06, 0.35),
    _BuildingData(0.16, 0.03, 0.60, hasSpire: true),
    _BuildingData(0.19, 0.06, 0.38),
    _BuildingData(0.25, 0.05, 0.28),
    _BuildingData(0.30, 0.04, 0.42),
    _BuildingData(0.34, 0.06, 0.50),
    _BuildingData(0.40, 0.04, 0.72, hasSpire: true),
    _BuildingData(0.44, 0.05, 0.38),
    _BuildingData(0.49, 0.04, 0.52, hasDome: true),
    _BuildingData(0.53, 0.06, 0.42),
    _BuildingData(0.59, 0.04, 0.32),
    _BuildingData(0.63, 0.05, 0.55),
    _BuildingData(0.68, 0.03, 0.65, hasSpire: true),
    _BuildingData(0.71, 0.05, 0.40),
    _BuildingData(0.76, 0.04, 0.30),
    _BuildingData(0.80, 0.06, 0.48),
    _BuildingData(0.86, 0.04, 0.35),
    _BuildingData(0.90, 0.05, 0.42),
    _BuildingData(0.95, 0.05, 0.32),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final silhouette = Paint()
      ..color = const Color(0xFF0E0419)
      ..style = PaintingStyle.fill;

    for (final b in _buildings) {
      final bx = b.x * size.width;
      final bw = b.width * size.width;
      final bh = b.height * size.height;
      final top = size.height - bh;

      canvas.drawRect(Rect.fromLTWH(bx, top, bw, bh), silhouette);

      if (b.hasSpire) {
        final spireH = bh * 0.16;
        final path = Path()
          ..moveTo(bx, top)
          ..lineTo(bx + bw * 0.5, top - spireH)
          ..lineTo(bx + bw, top)
          ..close();
        canvas.drawPath(path, silhouette);
      }

      if (b.hasDome) {
        final domeH = bh * 0.12;
        canvas.drawOval(
          Rect.fromLTWH(bx - bw * 0.05, top - domeH, bw * 1.1, domeH * 2),
          silhouette,
        );
      }
    }

    // Windows
    if (lightsProgress <= 0) return;

    final rng = math.Random(54321);
    for (final b in _buildings) {
      final bx = b.x * size.width;
      final bw = b.width * size.width;
      final bh = b.height * size.height;

      final cols = (bw / 6).floor().clamp(1, 5);
      final rows = (bh / 10).floor().clamp(1, 8);
      const wSize = 2.0;
      final colGap = bw / (cols + 1);
      final rowGap = bh / (rows + 1);

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final threshold = rng.nextDouble();
          if (threshold > lightsProgress * 1.4) continue;

          final wx = bx + (c + 1) * colGap - wSize / 2;
          final wy = size.height - bh + (r + 1) * rowGap - wSize / 2;

          final warmth = rng.nextDouble();
          final baseColor = Color.lerp(
            const Color(0xFFFFE082),
            const Color(0xFFFFB74D),
            warmth,
          )!;

          final intensity =
              ((lightsProgress * 1.4 - threshold) * 2.5).clamp(0.0, 1.0);

          // Glow
          canvas.drawCircle(
            Offset(wx + wSize / 2, wy + wSize / 2),
            wSize * 1.8,
            Paint()
              ..color = baseColor.withValues(alpha: intensity * 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );

          // Window
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, wSize, wSize),
            Paint()..color = baseColor.withValues(alpha: intensity * 0.8),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter old) =>
      old.lightsProgress != lightsProgress;
}
