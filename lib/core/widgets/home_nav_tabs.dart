import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Onglet actif courant dans la nav secondaire.
///
/// Chaque tab pointe vers une des pages "mode" (routes /mode/xxx) qui sont
/// egalement accessibles depuis l'Explorer.
enum HomeNavTab { food, famille, sport, culture, night }

// Palette neon (spec design)
const _bgInk      = Color(0xFF0A0414);
const _surface    = Color(0xFF1A0E2E);
const _accent     = Color(0xFFA855F7);
const _accentHi   = Color(0xFFC77DFF);
const _accentLo24 = Color(0x24A855F7);
const _accentBlur = Color(0xAAA855F7);
const _accentGlow = Color(0x55A855F7);
const _textHi     = Color(0xFFF5F0FF);
const _inactiveIcon = Color(0xFF6B5C8A);

/// Barre de navigation horizontale neon (cercles 56x56 + label dessous).
/// Spec : surface #1A0E2E, border 1.5px #A855F7 (actif) ou #A855F724 (inactif),
/// glow externe blur 22 + 44 quand actif.
class HomeNavTabs extends ConsumerWidget {
  final HomeNavTab? active;

  const HomeNavTabs({super.key, this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Padding 16 horizontal pour aligner le 1er bouton (Home) sur l'icône
    // MaCity du brand row (lui aussi à 16px du bord). spaceBetween → pas de
    // gap aux extrémités, gros gaps entre boutons.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const slots = 5;
          final slotWidth = constraints.maxWidth / slots;
          final circle = (slotWidth * 0.62).clamp(48.0, 58.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btn(context, ref, HomeNavTab.food, Icons.restaurant_rounded, 'Food', circle),
              _btn(context, ref, HomeNavTab.famille, Icons.family_restroom_rounded, 'Famille', circle),
              _btn(context, ref, HomeNavTab.sport, Icons.sports_soccer_rounded, 'Sport', circle),
              _btn(context, ref, HomeNavTab.culture, Icons.theater_comedy_rounded, 'Culture', circle),
              _btn(context, ref, HomeNavTab.night, Icons.nightlife_rounded, 'Night', circle),
            ],
          );
        },
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    WidgetRef ref,
    HomeNavTab tab,
    IconData icon,
    String label,
    double size, {
    bool showLiveDot = false,
  }) {
    final isActive = tab == active;
    final iconSize = size * 0.42;
    final dotSize = (size * 0.16).clamp(7.0, 9.0);
    final fontSize = (size * 0.20).clamp(8.5, 10.5);
    return GestureDetector(
      onTap: isActive ? null : () => _navigate(context, ref, tab),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isActive)
                Container(
                  width: size + 24,
                  height: size + 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_accentGlow, Colors.transparent],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surface,
                  border: Border.all(
                    color: isActive ? _accent : _accentLo24,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(color: _accentBlur, blurRadius: 22),
                          BoxShadow(color: _accentGlow, blurRadius: 44),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isActive ? _accentHi : _inactiveIcon,
                ),
              ),
              if (showLiveDot)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF472B6),
                      shape: BoxShape.circle,
                      border: Border.all(color: _bgInk, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Color(0xCCF472B6), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.05,
              color: isActive ? _textHi : _textHi.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, HomeNavTab tab) {
    // On synchronise aussi le currentMode (utilise par AppShell, back button,
    // etc.) pour que la nav bar du bas et le pop route sachent ou on est.
    final mode = switch (tab) {
      HomeNavTab.food    => 'food',
      HomeNavTab.famille => 'family',
      HomeNavTab.sport   => 'sport',
      HomeNavTab.culture => 'culture',
      HomeNavTab.night   => 'night',
    };
    ref.read(currentModeProvider.notifier).setMode(mode);
    context.go('/mode/$mode');
  }
}
