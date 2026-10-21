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

/// Bouton « bon plan du jour » dans le bandeau sombre du haut de la Home
/// (handoff design « piste C · Bandeau soirée », 2026-10-21) : surtitre jour
/// + nombre de sorties, message, flèche ronde. Ouvre la page des bons plans.
class TonightCtaBanner extends ConsumerStatefulWidget {
  const TonightCtaBanner({super.key});

  @override
  ConsumerState<TonightCtaBanner> createState() => _TonightCtaBannerState();
}

class _TonightCtaBannerState extends ConsumerState<TonightCtaBanner> {
  double _scale = 1;

  static final _titleStyle = GoogleFonts.outfit(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: Colors.white,
  );

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

    // Le compteur passe dans la ligne du jour (« LUNDI · 23 SORTIES »).
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
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              // 110deg CSS : #5b2bd6 -> #c21fa0.
              gradient: const LinearGradient(
                begin: Alignment(-1, -0.36),
                end: Alignment(1, 0.36),
                colors: [Color(0xFF5B2BD6), Color(0xFFC21FA0)],
              ),
              // Pilule, comme les pastilles Events privés / Invitations
              // posées à côté (2026-10-21).
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC21FA0).withValues(alpha: 0.7),
                  blurRadius: 24,
                  spreadRadius: -12,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.28,
                          color: const Color(0xFFF3E6FF),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        // « Les bons plans » garde son dégradé chaud (jaune)
                        // d'avant ; le message « Rien aujourd'hui » reste blanc.
                        child: isConfirmedEmpty
                            ? Text(
                                context.l10n.tonightNothingToday,
                                maxLines: 1,
                                style: _titleStyle,
                              )
                            : ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => AppGradients
                                    .tonightAccentText
                                    .createShader(bounds),
                                child: Text(
                                  context.l10n.tonightTitle,
                                  maxLines: 1,
                                  style: _titleStyle,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 13,
                    color: Colors.white,
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
