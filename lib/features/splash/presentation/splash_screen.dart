import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final AnimationController _btnController;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _btnController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _btnFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );

    _btnSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _btnController.forward();
    });

    // appOpen logged when user taps "Entrer" (services are ready by then)
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prenomAsync = ref.watch(userPrenomProvider);
    final prenom = prenomAsync.valueOrNull ?? '';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
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
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  'assets/images/start-01.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                ),
                // Dark overlay gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        // Main text
                        Opacity(
                          opacity: _fadeIn.value,
                          child: Transform.scale(
                            scale: _scale.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  prenom.isNotEmpty
                                      ? 'Salut, $prenom'
                                      : 'Salut',
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Toutes les sorties\nde ta ville\ndans une seule app',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.3,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        // Enter button
                        AnimatedBuilder(
                          animation: _btnController,
                          builder: (context, _) {
                            return SlideTransition(
                              position: _btnSlide,
                              child: Opacity(
                                opacity: _btnFade.value,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ActivityService.instance.appOpen();
                                      context.go('/home');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1A0A2E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Entrer',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: bottomPadding + 32),
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
