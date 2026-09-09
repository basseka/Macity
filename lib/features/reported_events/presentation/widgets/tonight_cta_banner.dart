import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/tonight_events_sheet.dart';
import 'package:pulz_app/features/reported_events/state/tonight_events_provider.dart';

/// Bandeau "Quoi faire ce soir" tout en haut du feed home, entre la
/// recherche et les chips (À la une / Top / Offres). Seul élément nocturne
/// d'un écran Home par ailleurs clair — voir BOUTON_CE_SOIR.md pour la spec
/// complète (géométrie, dégradés, étoiles, lune).
class TonightCtaBanner extends ConsumerStatefulWidget {
  const TonightCtaBanner({super.key});

  @override
  ConsumerState<TonightCtaBanner> createState() => _TonightCtaBannerState();
}

class _TonightCtaBannerState extends ConsumerState<TonightCtaBanner> {
  double _scale = 1;

  void _setScale(double v) => setState(() => _scale = v);

  void _onTap() {
    HapticFeedback.lightImpact();
    TonightEventsSheet.show(context);
  }

  String _dayLabel() {
    final wd = DateFormat('EEEE', 'fr_FR').format(DateTime.now());
    if (wd.isEmpty) return 'Ce soir';
    return '${wd[0].toUpperCase()}${wd.substring(1)} soir';
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);
    final count = ref.watch(tonightEventsCountProvider);
    final hasEvents = count > 0;

    final kicker = '${_dayLabel()} · $city';
    final semanticsLabel = hasEvents
        ? 'Quoi faire ce soir à $city, $count ${count == 1 ? "sortie" : "sorties"}, bouton'
        : 'Rien ce soir à $city, regarde demain, bouton';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setScale(0.98),
        onTapUp: (_) => _setScale(1),
        onTapCancel: () => _setScale(1),
        onTap: _onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.tonightSky,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tonightShadow.withValues(alpha: 0.7),
                  blurRadius: 30,
                  spreadRadius: -12,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  const Positioned.fill(child: _StarsLayer()),
                  const Positioned(right: 74, top: 8, child: _Moon()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                kicker.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.geistMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.8,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              _TitleLine(hasEvents: hasEvents),
                            ],
                          ),
                        ),
                        const SizedBox(width: 13),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasEvents) ...[
                              _CounterPill(count: count),
                              const SizedBox(height: 3),
                            ],
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explorer',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Titre "Quoi faire ce soir ?" : le fragment "ce soir ?" est en degrade
/// chaud via ShaderMask, applique sur un Text separe (pas un TextSpan/
/// RichText, le shader ne s'y pose pas proprement — voir BOUTON_CE_SOIR.md
/// §10.1). `FittedBox` remplace le "reduire a 18px" de la spec : ca fait
/// tenir une ville longue sur une ligne sans jamais passer a deux lignes.
class _TitleLine extends StatelessWidget {
  const _TitleLine({required this.hasEvents});

  final bool hasEvents;

  static final _style = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.1,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    if (!hasEvents) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text('Rien ce soir ? Regarde demain', maxLines: 1, style: _style),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Quoi faire ', maxLines: 1, style: _style),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                AppGradients.tonightAccentText.createShader(bounds),
            child: Text('ce soir ?', maxLines: 1, style: _style),
          ),
        ],
      ),
    );
  }
}

/// Pastille compteur en verre depoli ("23 SORTIES"). BackdropFilter degrade
/// gracieusement : sur un appareil lent, le flou est juste imperceptible, le
/// fond blanc a 16% suffit deja a lire la pastille (voir §10.3).
class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99
        ? '99+ SORTIES'
        : '$count ${count == 1 ? "SORTIE" : "SORTIES"}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Text(
            label,
            style: GoogleFonts.geistMono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lune : degrade radial decale vers le haut-gauche + halo flou.
class _Moon extends StatelessWidget {
  const _Moon();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.36, -0.36),
            colors: [AppColors.moonCore, AppColors.moonEdge],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.moonEdge.withValues(alpha: 0.55),
              blurRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cinq etoiles statiques, positionnees en % de la surface — un
/// CustomPainter plutot qu'une pile de Positioned (moins couteux, un seul
/// repaint jamais redeclenche puisque shouldRepaint est figé à false).
class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarsPainter());
  }
}

class _Star {
  const _Star(this.x, this.y, this.radius, this.opacity);
  final double x, y, radius, opacity;
}

class _StarsPainter extends CustomPainter {
  static const _stars = [
    _Star(0.18, 0.28, 1.5, 0.90),
    _Star(0.62, 0.22, 1.5, 0.70),
    _Star(0.40, 0.68, 1.0, 0.60),
    _Star(0.82, 0.58, 1.5, 0.75),
    _Star(0.28, 0.78, 1.0, 0.50),
  ];

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      _paint.color = Colors.white.withValues(alpha: s.opacity);
      canvas.drawCircle(
        Offset(size.width * s.x, size.height * s.y),
        s.radius,
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
