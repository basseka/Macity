import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/home/state/feed_filter_intent_provider.dart';
import 'package:pulz_app/features/home/state/feed_mode_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/map_live_page.dart';

/// Onglet actif courant dans la nav secondaire.
enum HomeNavTab { feed, feed2, scene, event, clubbing, mapLive }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 5 boutons : largeur dispo / 5, capé à 56. Bonne respiration entre.
          const slots = 5;
          const padding = 6.0;
          final slotWidth = constraints.maxWidth / slots;
          final circle = (slotWidth - padding * 2).clamp(42.0, 56.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn(context, ref, HomeNavTab.feed, Icons.home_rounded, 'Home', circle),
              _btn(context, ref, HomeNavTab.feed2, Icons.dynamic_feed_rounded, 'Feed', circle),
              _btn(context, ref, HomeNavTab.scene, Icons.theater_comedy_rounded, 'Scène', circle),
              _btn(context, ref, HomeNavTab.event, Icons.event_rounded, 'Event', circle),
              _btn(context, ref, HomeNavTab.clubbing, Icons.nightlife_rounded, 'Club', circle),
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
    switch (tab) {
      case HomeNavTab.feed:
        ref.read(feedModeProvider.notifier).state = FeedMode.classic;
        ref.read(feedFilterIntentProvider.notifier).state = null;
        context.go('/home');
        break;
      case HomeNavTab.feed2:
        ref.read(feedModeProvider.notifier).state = FeedMode.feed2;
        ref.read(feedFilterIntentProvider.notifier).state = null;
        context.go('/home');
        break;
      case HomeNavTab.scene:
        ref.read(feedModeProvider.notifier).state = FeedMode.classic;
        ref.read(feedFilterIntentProvider.notifier).state = 'En Scène';
        context.go('/home');
        break;
      case HomeNavTab.event:
        ref.read(feedModeProvider.notifier).state = FeedMode.classic;
        ref.read(feedFilterIntentProvider.notifier).state = 'Event';
        context.go('/home');
        break;
      case HomeNavTab.clubbing:
        ref.read(feedModeProvider.notifier).state = FeedMode.classic;
        ref.read(feedFilterIntentProvider.notifier).state = 'Clubbing';
        context.go('/home');
        break;
      case HomeNavTab.mapLive:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MapLivePage()),
        );
        break;
    }
  }
}
