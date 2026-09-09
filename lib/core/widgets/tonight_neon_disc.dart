import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Pastille "Quoi faire ce soir" en enseigne néon : fond sombre, contour rose
/// vif + halo, anneau cyan en retrait, halo pulsant depuis le bas.
/// Voir PASTILLE_NEON.md. Remplace la bulle violette de [PartnersOfDaySection].
class TonightNeonDisc extends StatefulWidget {
  const TonightNeonDisc({
    super.key,
    required this.label,
    this.eventCount,
    required this.onTap,
  });

  final String label;
  final int? eventCount;
  final VoidCallback onTap;

  @override
  State<TonightNeonDisc> createState() => _TonightNeonDiscState();
}

class _TonightNeonDiscState extends State<TonightNeonDisc>
    with SingleTickerProviderStateMixin {
  static const _diameter = 96.0;
  // Marge de rendu autour du disque pour laisser respirer les flous des
  // ombres (halo) sans agrandir l'emplacement dans la rangée (OverflowBox).
  static const _bleed = 150.0;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  // Points de controle du §4 de la spec : le saut brusque entre 45% et 55%
  // est volontaire, c'est ce qui donne l'effet "tube neon pas tout a fait
  // stable" plutot qu'une respiration reguliere.
  late final Animation<double> _haloOpacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.70, end: 1.00)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.00, end: 0.55)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.55, end: 0.70)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 45,
    ),
  ]).animate(_pulse);

  double _scale = 1;
  bool _boost = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _boost = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _boost = false);
    });
    widget.onTap();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction <= 0) {
      if (_pulse.isAnimating) _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  String get _semanticsLabel {
    final count = widget.eventCount;
    if (count == null) return '${widget.label}, bouton';
    return '${widget.label}, $count ${count == 1 ? "sortie" : "sorties"}';
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('tonight-neon-disc'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Semantics(
        button: true,
        label: _semanticsLabel,
        child: SizedBox(
          width: 104,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 100),
                child: SizedBox(
                  width: _diameter,
                  height: _diameter,
                  child: OverflowBox(
                    maxWidth: _bleed,
                    maxHeight: _bleed,
                    child: AnimatedBuilder(
                      animation: _haloOpacity,
                      builder: (context, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulsingHalo(
                            diameter: _diameter,
                            opacity: _boost ? 1.0 : _haloOpacity.value,
                          ),
                          const _Disc(diameter: _diameter),
                          const _CyanRing(diameter: _diameter),
                          const _GlassNoteIcon(),
                          // Zone tactile circulaire exacte (pas un carre
                          // invisible qui deborderait sur le halo).
                          ClipOval(
                            child: SizedBox(
                              width: _diameter,
                              height: _diameter,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) => setState(() => _scale = 0.94),
                                onTapUp: (_) => setState(() => _scale = 1),
                                onTapCancel: () => setState(() => _scale = 1),
                                onTap: _handleTap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.01 * 15,
                  height: 1.18,
                  color: const Color(0xFF1A1533),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Degrade radial partant du bas du cercle (§4), opacite animee par
/// l'appelant.
class _PulsingHalo extends StatelessWidget {
  const _PulsingHalo({required this.diameter, required this.opacity});

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(0, 1),
            radius: 0.62,
            colors: [
              AppColors.neonPink.withValues(alpha: 0.40),
              AppColors.neonPink.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fond sombre + contour rose vif avec son halo double (§2-3).
class _Disc extends StatelessWidget {
  const _Disc({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neonBg,
        border: Border.all(color: AppColors.neonPink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.15),
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.55),
            blurRadius: 22,
          ),
        ],
      ),
    );
  }
}

/// Anneau cyan en retrait de 9 avec sa propre lueur (§2-3).
class _CyanRing extends StatelessWidget {
  const _CyanRing({required this.diameter});

  final double diameter;
  static const _inset = 9.0;

  @override
  Widget build(BuildContext context) {
    final ringSize = diameter - _inset * 2;
    return Container(
      width: ringSize,
      height: ringSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.50),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

/// Verre (blanc, leger halo) + note de musique (cyan, sans halo propre),
/// composes cote a cote dans une boite de 40x40 (§5).
class _GlassNoteIcon extends StatelessWidget {
  const _GlassNoteIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.nightlife_rounded,
            color: Colors.white,
            size: 30,
            shadows: [
              Shadow(color: Color(0xCCFFFFFF), blurRadius: 6),
            ],
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Icon(
              Icons.music_note_rounded,
              color: AppColors.neonCyan,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
