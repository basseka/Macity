import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/core/widgets/home_quick_pills.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/home_private_buttons.dart';
import 'package:pulz_app/features/reported_events/presentation/map_live_page.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/tonight_cta_banner.dart';

/// Haut de la Home (handoff design « piste C · Bandeau soirée », 2026-10-21) :
/// profil + ville + Map Live et recherche avec calendrier sur le fond clair,
/// puis une carte sombre avec bon plan du jour + events privés/invitations.
/// Les onglets À la une / Top / Offres restent dessous, sur le fond clair.
///
/// La recherche et le calendrier restent pilotés par FeedScreen (état de
/// recherche et vue résultats par dates), d'où les deux callbacks.
class HomeHeaderBand extends ConsumerWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCalendarTap;

  const HomeHeaderBand({
    super.key,
    required this.onSearchTap,
    required this.onCalendarTap,
  });

  // Éclairci (maquette : #1a0b26) à la demande, 2026-10-21.
  static const _ink = Color(0xFF2E1A45);
  static const _dim = Color(0xFF6B5A7C);
  static const _pink = Color(0xFFE8177A);
  // Nom de la ville en noir franc (demande 2026-10-21).
  static const _text = Color(0xFF000000);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileRow(),
          const SizedBox(height: 9),
          _SearchField(
            onSearchTap: onSearchTap,
            onCalendarTap: onCalendarTap,
          ),
          const SizedBox(height: 8),
          // Depuis le 2026-10-21, la carte sombre n'englobe plus que la
          // ligne bons plans + events privés + invitations ; profil et
          // recherche passent sur le fond clair au-dessus.
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Stack(
              children: [
                // Halos : magenta en haut à droite, violet en bas à gauche.
                Positioned(
                  top: -200,
                  right: -260,
                  child: _Halo(
                    width: 520,
                    height: 400,
                    color: Color(0xA6E8177A),
                  ),
                ),
                Positioned(
                  bottom: -220,
                  left: -260,
                  child: _Halo(
                    width: 520,
                    height: 440,
                    color: Color(0xB37B3FE4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  // Bons plans + events privés + invitations sur une ligne,
                  // à la même hauteur.
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: TonightCtaBanner()),
                        SizedBox(width: 6),
                        Flexible(flex: 3, child: HomePrivateButtons()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Halo radial elliptique (équivalent du radial-gradient CSS, transparent à
/// 70 % du rayon).
class _Halo extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _Halo({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: Transform.scale(
          scaleX: width / height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0)],
                stops: const [0, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prenom = ref.watch(userPrenomProvider).valueOrNull ?? '';
    final avatarUrl = ref.watch(userAvatarUrlProvider).valueOrNull;
    final city = ref.watch(selectedCityProvider);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => AccountMenu.show(context, ref),
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: HomeHeaderBand._pink,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A9C), HomeHeaderBand._pink],
                ),
                image: avatarUrl != null && avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? null
                  : const Icon(Icons.person, color: Colors.white, size: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CityPickerBottomSheet(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prenom.isNotEmpty)
                  Text(
                    prenom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: HomeHeaderBand._dim,
                    ),
                  ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.15,
                          color: HomeHeaderBand._text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: HomeHeaderBand._text,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        MapLivePill(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MapLivePage()),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCalendarTap;

  const _SearchField({required this.onSearchTap, required this.onCalendarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.fromLTRB(10, 0, 3, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x141A0B26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSearchTap,
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: HomeHeaderBand._dim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.feedSearchPlaceholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: HomeHeaderBand._dim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onCalendarTap,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EEF3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: HomeHeaderBand._pink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
