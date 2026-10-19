import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/l10n/labels.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/screens/tonight_bons_plans_page.dart';
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
    TonightBonsPlansPage.show(context);
  }

  String _dayLabel() {
    final wd = DateFormat('EEEE', context.dateLocale).format(DateTime.now());
    if (wd.isEmpty) return context.l10n.commonToday;
    return '${wd[0].toUpperCase()}${wd.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);
    final count = ref.watch(tonightEventsCountProvider);
    final fetchFailed = ref.watch(tonightEventsFetchFailedProvider);
    final hasPill = count > 0;
    // Sur erreur reseau on ne sait pas s'il y a des events ou non : on ne
    // doit jamais afficher "Rien aujourd'hui" (ca affirme a tort une liste
    // vide confirmee), seulement quand le fetch a reellement reussi.
    final isConfirmedEmpty = !fetchFailed && count == 0;

    // Le compteur passe dans la ligne du jour (« LUNDI · 23 SORTIES ») : le
    // bandeau partage sa ligne avec les raccourcis events privés, la place
    // va au titre, sinon illisible.
    final kicker = hasPill
        ? '${_dayLabel()} · ${count > 99 ? context.l10n.tonightOutingsMany : context.l10n.tonightOutingsCount(count)}'
        : _dayLabel();
    final semanticsLabel = isConfirmedEmpty
        ? context.l10n.tonightA11yEmpty(city)
        : hasPill
            ? context.l10n.tonightA11yCount(count, city)
            : context.l10n.tonightA11y(city);

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
            height: 46,
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
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
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
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                _TitleLine(isConfirmedEmpty: isConfirmedEmpty),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
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
  const _TitleLine({required this.isConfirmedEmpty});

  final bool isConfirmedEmpty;

  static final _style = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.1,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    if (isConfirmedEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.tonightNothingToday,
          maxLines: 1,
          style: _style,
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            AppGradients.tonightAccentText.createShader(bounds),
        child: Text(context.l10n.tonightTitle, maxLines: 1, style: _style),
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
