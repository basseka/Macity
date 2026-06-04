import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_city_header.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/offer_detail_screen.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';

/// Ecran "Explorer" — feed des offres.
///
/// Layout :
///  1. CityHeader (logo + Ta ville + ville + avatar)
///  2. Header "Toutes les *offres*"
///  3. Grille 2 colonnes des offres actives (tap -> OfferCodePopup)
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explorer = écran clair. On force le thème clair pour ne pas hériter
    // du flag global laissé à false par Night (mode_shell).
    AppColors.isLightTheme = true;
    final offersAsync = ref.watch(activeOffersProvider);

    return Scaffold(
      backgroundColor: EditorialColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: EditorialCityHeader()),
            // Header "Toutes les offres"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EditorialSpacing.screen,
                  EditorialSpacing.lg,
                  EditorialSpacing.screen,
                  EditorialSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '✦',
                      style: TextStyle(
                        color: EditorialColors.magenta,
                        fontSize: 18,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: EditorialSpacing.md),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Toutes les offres par ',
                              style: EditorialText.displayTitle()
                                  .copyWith(fontSize: 18),
                            ),
                            // Logo BeThere a la place du mot, aligne avec
                            // la baseline du texte. La hauteur du logo (28)
                            // est legerement superieure a la x-height du
                            // texte 18pt pour mieux ressortir.
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Image.asset(
                                  'assets/images/bethere-logo.png',
                                  height: 60,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Grille des offres
            ..._buildOffersSlivers(context, ref, offersAsync),
            const SliverToBoxAdapter(
              child: SizedBox(height: EditorialSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOffersSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Offer>> offersAsync,
  ) {
    return offersAsync.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.magenta),
            ),
          ),
        ),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Impossible de charger les offres',
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ),
        ),
      ],
      data: (offers) {
        if (offers.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Aucune offre disponible',
                    style: GoogleFonts.geist(
                      fontSize: 13,
                      color: AppColors.textFaint,
                    ),
                  ),
                ),
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              EditorialSpacing.screen,
              4,
              EditorialSpacing.screen,
              4,
            ),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.58,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _OfferCard(
                  offer: offers[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfferDetailScreen(offer: offers[i]),
                    ),
                  ),
                ),
                childCount: offers.length,
              ),
            ),
          ),
        ];
      },
    );
  }
}

/// Carte offre large pour la grille 2 colonnes : image + titre + commerce
/// + badge places restantes.
class _OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;

  const _OfferCard({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visuel
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: offer.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(
                          color: Color(0xFF241338),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE8A0BF),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _emojiFallback(),
                      )
                    else
                      _emojiFallback(),
                    // Degrade bas pour lisibilite
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF1A0A2E).withValues(alpha: 0.85),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Badge places restantes
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: offer.hasSpots
                              ? const Color(0xFFE8A0BF).withValues(alpha: 0.22)
                              : Colors.red.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: offer.hasSpots
                                ? const Color(0xFFE8A0BF)
                                    .withValues(alpha: 0.4)
                                : Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          offer.isUnlimited
                              ? '∞ Illimite'
                              : (offer.hasSpots
                                  ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''}'
                                  : 'Complet'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: offer.hasSpots
                                ? const Color(0xFFE8A0BF)
                                : Colors.red.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Infos
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (offer.emoji.isNotEmpty) ...[
                            Text(
                              offer.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (offer.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          offer.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFE8A0BF),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              offer.businessName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiFallback() {
    return ColoredBox(
      color: const Color(0xFF241338),
      child: Center(
        child: Text(
          offer.emoji.isNotEmpty ? offer.emoji : '🎁',
          style: const TextStyle(fontSize: 44),
        ),
      ),
    );
  }
}
