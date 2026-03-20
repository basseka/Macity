import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Banniere publicitaire animee simulee.
/// Carousel de slides avec transition automatique toutes les 4 secondes.
class AnimatedAdBanner extends StatefulWidget {
  const AnimatedAdBanner({super.key});

  @override
  State<AnimatedAdBanner> createState() => _AnimatedAdBannerState();
}

class _AnimatedAdBannerState extends State<AnimatedAdBanner>
    with SingleTickerProviderStateMixin {
  static const _slides = <_AdSlide>[
    _AdSlide(
      title: 'Concert ce soir !',
      subtitle: 'Reservez vos places maintenant',
      cta: 'En savoir plus',
      gradient: [Color(0xFFE91E8C), Color(0xFF7B2D8E)],
      icon: Icons.music_note_rounded,
    ),
    _AdSlide(
      title: '-20% sur les spectacles',
      subtitle: 'Offre exclusive MaCity',
      cta: 'Voir l\'offre',
      gradient: [Color(0xFFFF6B35), Color(0xFFE91E63)],
      icon: Icons.local_offer_rounded,
    ),
    _AdSlide(
      title: 'Match du Stade Toulousain',
      subtitle: 'Samedi 20h - Ernest Wallon',
      cta: 'Billetterie',
      gradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
      icon: Icons.sports_rugby_rounded,
    ),
    _AdSlide(
      title: 'Food Festival Toulouse',
      subtitle: 'Ce week-end au Capitole',
      cta: 'Decouvrir',
      gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      icon: Icons.restaurant_rounded,
    ),
  ];

  late final PageController _pageController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SizedBox(
        height: 72,
        child: Stack(
          children: [
            // Carousel
            PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return _buildSlide(slide);
              },
            ),
            // Dots indicator
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _currentPage ? 14 : 5,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i == _currentPage
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            // Badge "AD"
            Positioned(
              top: 6,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AD',
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_AdSlide slide) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: slide.gradient.first.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => debugPrint('[Ad] tap: ${slide.title}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
            child: Row(
              children: [
                // Icone animee
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slide.icon, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slide.title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slide.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton CTA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    slide.cta,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: slide.gradient.first,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdSlide {
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> gradient;
  final IconData icon;

  const _AdSlide({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.icon,
  });
}
