import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulz_app/core/services/activity_service.dart';

/// Splash d'accueil animé : feu d'artifice de particules + "Macity / Ma ville,
/// mes sorties". Auto-transition vers /home après ~2.8s.
class TotoSplashScreen extends StatefulWidget {
  const TotoSplashScreen({super.key});

  @override
  State<TotoSplashScreen> createState() => _TotoSplashScreenState();
}

class _TotoSplashScreenState extends State<TotoSplashScreen>
    with TickerProviderStateMixin {
  // Animations texte
  late final AnimationController _textCtrl;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;
  late final Animation<double> _outroFade;

  // Moteur particules
  late final Ticker _ticker;
  final List<_Firework> _fireworks = [];
  final Random _rng = Random();
  Duration _lastTick = Duration.zero;
  Duration _lastSpawn = Duration.zero;
  Size _canvasSize = Size.zero;

  static const _total = Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();

    _textCtrl = AnimationController(vsync: this, duration: _total);

    // Intervalles recalculés pour _total = 4500ms :
    //   Titre      : ~900ms -> ~2000ms  (0.20 -> 0.45)
    //   Sous-titre : ~2000ms -> ~3100ms (0.45 -> 0.70)
    //   Fade-out   : ~4050ms -> 4500ms  (0.90 -> 1.0)
    _titleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.20, 0.45, curve: Curves.easeOut),
    );
    _titleScale = Tween(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.20, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _subFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.45, 0.70, curve: Curves.easeOut),
    );
    _subSlide = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
    ));
    _outroFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    _textCtrl.forward();
    _ticker = createTicker(_onTick)..start();

    // Spawn immédiat d'un premier feu d'artifice dès qu'on a la taille
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _canvasSize != Size.zero) {
        _spawnFirework();
      }
    });

    Future.delayed(_total, _goHome);
  }

  void _onTick(Duration elapsed) {
    if (_canvasSize == Size.zero) return;

    final dt = _lastTick == Duration.zero
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    // Fréquence spawn : 1 explosion / 260ms, stop à 3800ms (derrières 700ms
    // pour laisser les particules en vol s'éteindre proprement avant le fade-out).
    final spawnWindow = elapsed <= const Duration(milliseconds: 3800);
    if (spawnWindow &&
        elapsed - _lastSpawn > const Duration(milliseconds: 260)) {
      _spawnFirework();
      _lastSpawn = elapsed;
    }

    for (final fw in _fireworks) {
      fw.update(dt);
    }
    _fireworks.removeWhere((fw) => fw.isDead);

    if (mounted) setState(() {});
  }

  void _spawnFirework() {
    final origin = Offset(
      _rng.nextDouble() * _canvasSize.width * 0.9 + _canvasSize.width * 0.05,
      _rng.nextDouble() * _canvasSize.height * 0.5 + _canvasSize.height * 0.12,
    );
    _fireworks.add(_Firework(origin: origin, rng: _rng));
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
    _ticker.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _canvasSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      body: AnimatedBuilder(
        animation: _textCtrl,
        builder: (_, __) {
          return Opacity(
            opacity: _outroFade.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient de fond
                Container(
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
                      stops: [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
                // Halo radial central discret
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        const Color(0xFF8E24AA).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Feux d'artifice
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _FireworksPainter(_fireworks),
                    size: Size.infinite,
                  ),
                ),
                // Vignette basse
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0.65, 1.0],
                    ),
                  ),
                ),
                // Texte
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _titleFade,
                          child: ScaleTransition(
                            scale: _titleScale,
                            child: Text(
                              'Macity',
                              style: GoogleFonts.poppins(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.0,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFE91E63)
                                        .withValues(alpha: 0.55),
                                    blurRadius: 18,
                                  ),
                                  Shadow(
                                    color: const Color(0xFF8E24AA)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _subFade,
                          child: SlideTransition(
                            position: _subSlide,
                            child: Text(
                              'Ma ville, mes sorties',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.greatVibes(
                                fontSize: 32,
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 4),
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
}

// ═══════════════════════════════════════════════════════════════
// MOTEUR DE PARTICULES — feu d'artifice
// ═══════════════════════════════════════════════════════════════

class _Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double maxLife;
  final double size;
  final double twinkleSpeed;
  double life;
  double age = 0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    required this.size,
    required this.twinkleSpeed,
  }) : life = maxLife;

  bool get isDead => life <= 0;

  double get opacity {
    final t = (life / maxLife).clamp(0.0, 1.0);
    final fade = t; // linéaire pour plus de visibilité
    final twinkle = 0.85 + 0.15 * sin(age * twinkleSpeed);
    return fade * twinkle;
  }

  void update(double dt) {
    position = position + velocity * dt;
    velocity = Offset(velocity.dx * 0.97, velocity.dy * 0.97 + 55 * dt);
    life -= dt;
    age += dt;
  }
}

class _Firework {
  final List<_Particle> particles = [];

  _Firework({required Offset origin, required Random rng}) {
    const palette = [
      Color(0xFFE91E63), // magenta
      Color(0xFF8E24AA), // violet
      Color(0xFFFFD54F), // jaune
      Color(0xFFFF6BAA), // rose pâle
      Color(0xFFFFFFFF), // blanc
      Color(0xFF42A5F5), // bleu clair (variété)
    ];
    final c1 = palette[rng.nextInt(palette.length)];
    final c2 = rng.nextDouble() < 0.35
        ? palette[rng.nextInt(palette.length)]
        : c1;

    final count = 55 + rng.nextInt(25); // 55-80 particules
    final speedBase = 80 + rng.nextDouble() * 70; // 80-150 px/s (plus ample)

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = speedBase * (0.4 + rng.nextDouble() * 0.8);
      final color = rng.nextBool() ? c1 : c2;
      particles.add(_Particle(
        position: origin,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        maxLife: 1.0 + rng.nextDouble() * 0.9, // 1.0-1.9s
        size: 2.0 + rng.nextDouble() * 1.8, // 2.0-3.8 px (plus visible)
        twinkleSpeed: 10 + rng.nextDouble() * 20,
      ));
    }
  }

  bool get isDead => particles.every((p) => p.isDead);

  void update(double dt) {
    for (final p in particles) {
      if (!p.isDead) p.update(dt);
    }
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;

  _FireworksPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      for (final p in fw.particles) {
        if (p.isDead) continue;

        // Halo (blur)
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity * 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 2.5);
        canvas.drawCircle(p.position, p.size * 2.5, glowPaint);

        // Cœur brillant
        final corePaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity);
        canvas.drawCircle(p.position, p.size, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}
