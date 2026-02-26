import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
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
            child: Center(
              child: Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
