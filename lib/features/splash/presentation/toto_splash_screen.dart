import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulz_app/core/services/activity_service.dart';

/// Tokens splash "Macity." — handoff design (mai 2026).
class MacityColors {
  static const bg = Color(0xFF06061B);
  static const pink = Color(0xFFFF1E8E);
  static const hotPink = Color(0xFFFF1E7B);
  static const red = Color(0xFFFF2E38);

  static const LinearGradient grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, red],
  );
}

/// Splash d'accueil "Macity." — fond radial pulsant + halo glow + ondes
/// + pin (CustomPaint) bounce-in + wordmark + loader. Auto-transition /home.
class TotoSplashScreen extends StatefulWidget {
  const TotoSplashScreen({super.key});

  @override
  State<TotoSplashScreen> createState() => _TotoSplashScreenState();
}

class _TotoSplashScreenState extends State<TotoSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _loop;
  late final AnimationController _ripple;
  late final AnimationController _word;
  late final AnimationController _loader;
  late final AnimationController _outro;

  // Timeline kit + 5 s d'affichage supplémentaire avant transition.
  static const _dismissAt = Duration(milliseconds: 6600);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _word = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _word.forward();
    });

    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _loader.forward();
    });

    _outro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    Timer(_dismissAt - const Duration(milliseconds: 400), () {
      if (mounted) _outro.forward();
    });
    Timer(_dismissAt, _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    imageCache.clear();
    imageCache.clearLiveImages();
    ActivityService.instance.appOpen();
    context.go('/home');
  }

  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    _ripple.dispose();
    _word.dispose();
    _loader.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MacityColors.bg,
      body: AnimatedBuilder(
        animation: _outro,
        builder: (_, child) => Opacity(
          opacity: 1.0 - Curves.easeIn.transform(_outro.value),
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond atmosphérique ──────────────────────────────
            AnimatedBuilder(
              animation: _loop,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_loop.value);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.3),
                      radius: 1.2,
                      colors: [
                        Color.lerp(const Color(0xFF1F1F4A),
                            const Color(0xFF2A2A60), t)!,
                        const Color(0xFF0A0A26),
                        const Color(0xFF04041A),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),

            // ── Halo rose central — glow doux qui respire ───────
            Center(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) {
                  final p = Curves.easeInOut.transform(_loop.value);
                  final scale = 0.90 + 0.16 * p;
                  return Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 480,
                          height: 480,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                MacityColors.hotPink
                                    .withValues(alpha: 0.09 + 0.05 * p),
                                MacityColors.hotPink
                                    .withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MacityColors.pink
                                .withValues(alpha: 0.04 + 0.04 * p),
                            boxShadow: [
                              BoxShadow(
                                color: MacityColors.pink
                                    .withValues(alpha: 0.18 + 0.12 * p),
                                blurRadius: 70 + 20 * p,
                                spreadRadius: 2 + 6 * p,
                              ),
                              BoxShadow(
                                color: MacityColors.red
                                    .withValues(alpha: 0.12 + 0.08 * p),
                                blurRadius: 40,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Ondes au sol (ellipses plates horizontales) ─────
            Center(
              child: Transform.translate(
                offset: const Offset(0, 92),
                child: SizedBox(
                  width: 240,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: List.generate(3, (i) {
                      return AnimatedBuilder(
                        animation: _ripple,
                        builder: (_, __) {
                          final phase = ((_ripple.value + i / 3) % 1.0);
                          final scale = 0.35 + phase * 2.0;
                          final opacity =
                              ((1.0 - phase) * 0.45).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 130,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(65, 12),
                                  ),
                                  border: Border.all(
                                    color: MacityColors.hotPink,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),

            // ── Pin + wordmark ──────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _enter,
                    builder: (_, child) {
                      final v = _enter.value.clamp(0.0, 1.0);
                      final t = Curves.elasticOut.transform(v);
                      return Opacity(
                        opacity: v,
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * t,
                          child: child,
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: 160,
                        height: 178,
                        child: CustomPaint(painter: _PinPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _word,
                    builder: (_, child) {
                      final t = Curves.easeOut.transform(_word.value);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 12),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Macity',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.4,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (rect) =>
                                  MacityColors.grad.createShader(rect),
                              child: Text(
                                '.',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LA VILLE, EN DIRECT',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            letterSpacing: 4,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Loader bas ──────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: AnimatedBuilder(
                animation: _loader,
                builder: (_, child) {
                  final t = Curves.easeOut.transform(_loader.value);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 10),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CHARGEMENT',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LoaderBar(controller: _loop),
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

/// Pin pink→red recréé depuis le SVG du kit (viewBox 200×220), sans
/// dépendance flutter_svg.
class _PinPainter extends CustomPainter {
  const _PinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200.0;
    final sy = size.height / 220.0;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(100, 205), width: 44, height: 6),
      Paint()..color = const Color(0xFFFFC8DC).withValues(alpha: 0.22),
    );

    final body = Path()
      ..moveTo(100, 8)
      ..cubicTo(145, 8, 180, 42, 180, 86)
      ..cubicTo(180, 130, 152, 158, 122, 184)
      ..cubicTo(113, 192, 107, 198, 103, 202)
      ..cubicTo(101, 204, 99, 204, 97, 202)
      ..cubicTo(93, 198, 87, 192, 78, 184)
      ..cubicTo(48, 158, 20, 130, 20, 86)
      ..cubicTo(20, 42, 55, 8, 100, 8)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF1E8E),
            Color(0xFFFF1E6E),
            Color(0xFFFF2E38),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 220)),
    );

    canvas.drawCircle(
      const Offset(100, 83),
      22,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.2),
          radius: 0.8,
          colors: [Color(0xFF1A0822), Color(0xFF06061B)],
        ).createShader(
            Rect.fromCircle(center: const Offset(100, 83), radius: 22)),
    );

    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.56),
          radius: 0.4,
          colors: [
            const Color(0xFFFFD2E1).withValues(alpha: 0.7),
            const Color(0xFFFFD2E1).withValues(alpha: 0.0),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 220))
        ..blendMode = BlendMode.srcATop,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => false;
}

/// Barre loader avec balayage dégradé.
class _LoaderBar extends StatelessWidget {
  final AnimationController controller;
  const _LoaderBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final x = -56 + controller.value * 196;
            return Stack(
              children: [
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          MacityColors.pink,
                          MacityColors.red,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MacityColors.hotPink
                              .withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
