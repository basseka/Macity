import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/activity_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Texte
  late final AnimationController _textCtrl;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;
  late final Animation<double> _outroFade;

  // Feux d'artifice
  late final Ticker _ticker;
  final List<_Firework> _fireworks = [];
  final Random _rng = Random();
  Duration _lastTick = Duration.zero;
  Duration _lastSpawn = Duration.zero;
  Size _canvasSize = Size.zero;

  static const _total = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();

    _textCtrl = AnimationController(vsync: this, duration: _total);

    // Titre "Macity" : fade + scale entre 20% et 50% (~560ms → 1400ms)
    _titleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.20, 0.50, curve: Curves.easeOut),
    );
    _titleScale = Tween(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Sous-titre cursif : fade + slide entre 45% et 75% (~1260ms → 2100ms)
    _subFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _subSlide = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
    ));

    // Fade-out global dans les 300 dernières ms pour une transition douce
    _outroFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    _textCtrl.forward();

    _ticker = createTicker(_onTick)..start();

    // Transition automatique vers /home
    Future.delayed(_total, _goHome);
  }

  void _onTick(Duration elapsed) {
    if (_canvasSize == Size.zero) return;
    final dt = _lastTick == Duration.zero
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    // Spawn d'une nouvelle explosion toutes ~320ms, stoppe après 2s
    // pour que l'écran soit calme au moment du transit.
    final spawnOk = elapsed <= const Duration(milliseconds: 2100);
    if (spawnOk && elapsed - _lastSpawn > const Duration(milliseconds: 320)) {
      _spawnFirework();
      _lastSpawn = elapsed;
    }

    // Update particles
    for (final fw in _fireworks) {
      fw.update(dt);
    }
    _fireworks.removeWhere((fw) => fw.isDead);

    if (mounted) setState(() {});
  }

  void _spawnFirework() {
    final origin = Offset(
      _rng.nextDouble() * _canvasSize.width * 0.9 + _canvasSize.width * 0.05,
      _rng.nextDouble() * _canvasSize.height * 0.55 + _canvasSize.height * 0.10,
    );
    _fireworks.add(_Firework(origin: origin, rng: _rng));
  }

  void _goHome() {
    if (!mounted) return;
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
    // Mesurer la taille de l'écran pour le spawn
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
                // Gradient radial + linéaire pour l'ambiance nuit profonde
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
                // Halo radial discret au centre
                Container(
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
                // Feux d'artifice animés
                CustomPaint(
                  painter: _FireworksPainter(_fireworks),
                  size: Size.infinite,
                ),
                // Vignette bas pour faire ressortir le texte
                Container(
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
                                fontSize: 72,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -2.0,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFE91E63)
                                        .withValues(alpha: 0.55),
                                    blurRadius: 28,
                                  ),
                                  Shadow(
                                    color: const Color(0xFF8E24AA)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 42,
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
                                fontSize: 40,
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 12,
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
// MOTEUR DE PARTICULES : feux d'artifice
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
    // Fade non-linéaire + scintillement subtil
    final fade = t * t;
    final twinkle = 0.8 + 0.2 * sin(age * twinkleSpeed);
    return fade * twinkle;
  }

  void update(double dt) {
    position = position + velocity * dt;
    // Friction air + gravité légère (retombée des sparks)
    velocity = Offset(velocity.dx * 0.97, velocity.dy * 0.97 + 55 * dt);
    life -= dt;
    age += dt;
  }
}

class _Firework {
  final List<_Particle> particles = [];

  _Firework({required Offset origin, required Random rng}) {
    // Palette brand : magenta, violet, jaune, rose pâle, blanc chaud
    const palette = [
      Color(0xFFE91E63),
      Color(0xFF8E24AA),
      Color(0xFFFFD54F),
      Color(0xFFFF6BAA),
      Color(0xFFFFFFFF),
    ];
    // Parfois 2 couleurs mixées pour un effet bicolore
    final c1 = palette[rng.nextInt(palette.length)];
    final c2 = rng.nextDouble() < 0.35
        ? palette[rng.nextInt(palette.length)]
        : c1;

    final count = 48 + rng.nextInt(28); // 48-75 particules
    final speedBase = 60 + rng.nextDouble() * 50; // 60-110 px/s

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      // Vitesse variable par particule (explosion inégale, plus réaliste)
      final speed = speedBase * (0.4 + rng.nextDouble() * 0.8);
      final color = rng.nextBool() ? c1 : c2;
      particles.add(_Particle(
        position: origin,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        maxLife: 0.9 + rng.nextDouble() * 0.9, // 0.9-1.8s
        size: 1.6 + rng.nextDouble() * 1.4, // 1.6-3.0 px
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

        // Glow halo (blur doux)
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity * 0.35)
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 3);
        canvas.drawCircle(p.position, p.size * 3, glowPaint);

        // Core brillant
        final corePaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..blendMode = BlendMode.plus;
        canvas.drawCircle(p.position, p.size, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}
