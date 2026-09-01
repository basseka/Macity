import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/offers/presentation/widgets/premium_offers_card.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_city_header.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/offer_detail_screen.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';

/// Ecran "Explorer" — feed des offres.
///
/// Layout (refonte handoff "Offres — refonte", fev. 2026) :
///  1. CityHeader (logo + Ta ville + ville + avatar)
///  2. Carte sombre "Offres premium" (logo BeThere + categories verrouillees)
///  3. Grille 2 colonnes des offres actives (tap -> OfferDetailScreen)
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explorer = écran clair. On force le thème clair pour ne pas hériter
    // du flag global laissé à false par Night (mode_shell).
    AppColors.isLightTheme = true;
    final offersAsync = ref.watch(activeOffersProvider);
    final selectedCategory = ref.watch(selectedOfferCategoryProvider);

    return Scaffold(
      // Fond crème du handoff, EN DUR : distinct du gris `EditorialColors.bg`
      // partagé avec le reste de l'app.
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: EditorialCityHeader()),
            const SliverToBoxAdapter(
              child: SizedBox(height: EditorialSpacing.sm),
            ),
            // Carte "Offres premium" : logo BeThere + 3 catégories
            // verrouillées + CTA d'abonnement, tout dans le même bloc sombre.
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: EditorialSpacing.screen),
                child: PremiumOffersCard(),
              ),
            ),
            // Sépare le teaser « réservé aux abonnés » de ce qui est réellement
            // disponible : sans ce titre, la grille se lisait comme la suite du
            // carrousel, donc comme du contenu verrouillé lui aussi.
            const SliverToBoxAdapter(child: _TitreOffresMaCity()),
            const SliverToBoxAdapter(child: _CategoryFilterRow()),
            const SliverToBoxAdapter(
              child: SizedBox(height: EditorialSpacing.sm),
            ),
            // Grille des offres
            ..._buildOffersSlivers(context, ref, offersAsync, selectedCategory),
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
    String? selectedCategory,
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
      data: (allOffers) {
        // Filtre applique cote client : la liste est deja courte (une seule
        // ville) et deja chargee par activeOffersProvider, inutile de
        // relancer une requete pour changer d'onglet.
        final offers = selectedCategory == null
            ? allOffers
            : allOffers.where((o) => o.categorie == selectedCategory).toList();
        if (offers.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    selectedCategory == null
                        ? 'Aucune offre disponible'
                        : 'Aucune offre dans cette categorie',
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
                // Carte blanche courte (image 112 + 3 lignes de texte max),
                // bien plus compacte que l'ancienne carte sombre a 4 lignes.
                childAspectRatio: 0.72,
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

/// Titre de section au-dessus de la grille : glyphe ◆ + "Les offres MaCity".
///
/// Couleurs EN DUR, comme dans `PremiumOffersCard` et pour les mêmes
/// raisons : `Theme.of(context)` hérite du thème global, qui est SOMBRE (texte
/// blanc sur fond crème = invisible), et `EditorialColors.text` dépend de
/// `AppColors.isLightTheme`, un drapeau global MUTABLE qu'un autre écran peut
/// laisser à false.
class _TitreOffresMaCity extends StatelessWidget {
  const _TitreOffresMaCity();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        EditorialSpacing.screen,
        EditorialSpacing.sm,
        EditorialSpacing.screen,
        EditorialSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            '◆',
            style: TextStyle(color: Color(0xFFF5197F), fontSize: 14),
          ),
          SizedBox(width: 8),
          // Expanded + ellipsis, par securite sur les ecrans etroits (les
          // enfants non-Expanded d'un Row ne se compressent pas d'eux-memes).
          Expanded(
            child: Text(
              'Les offres MaCity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101B33),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtres par categorie au-dessus de la grille : "Toutes" + les 5
/// categories d'offres. Filtrage cote client (cf. [_buildOffersSlivers]),
/// pas de requete reseau au changement d'onglet.
///
/// Couleurs EN DUR, meme raison que [_TitreOffresMaCity] : cet ecran force
/// le theme clair localement mais `EditorialColors`/`AppColors.isLightTheme`
/// restent un drapeau global partage avec les ecrans sombres.
class _CategoryFilterRow extends ConsumerWidget {
  const _CategoryFilterRow();

  static const _categories = [
    'Restaurant',
    'Soiree',
    'Sport',
    'Services',
    'Loisirs',
  ];

  static const _labels = {
    'Restaurant': 'Restaurant',
    'Soiree': 'Soirée',
    'Sport': 'Sport',
    'Services': 'Services',
    'Loisirs': 'Loisirs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedOfferCategoryProvider);

    Widget chip(String? value, String label) {
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 9),
        child: GestureDetector(
          onTap: () =>
              ref.read(selectedOfferCategoryProvider.notifier).state = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF5197F) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFF5197F).withValues(alpha: 0.65)
                      : const Color(0xFF101B33).withValues(alpha: 0.06),
                  blurRadius: isSelected ? 14 : 6,
                  offset: Offset(0, isSelected ? 6 : 2),
                  spreadRadius: isSelected ? -6 : 0,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF101B33),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: EditorialSpacing.screen,
        ),
        children: [
          chip(null, 'Toutes'),
          for (final c in _categories) chip(c, _labels[c]!),
        ],
      ),
    );
  }
}

/// Carte offre blanche pour la grille 2 colonnes : photo + badge places +
/// nom du commerce + titre de l'offre + adresse.
///
/// Le handoff design prevoit un badge remise chiffree (−20 %, OFFERT,
/// ENTREE) : le modele `Offer` ne porte aucun type/montant de remise
/// (uniquement des places, cf. `offer.dart`), donc le badge reste base sur
/// les places restantes reelles plutot que d'inventer une remise.
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
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101B33).withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: offer.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFFEFE6D6),
                      ),
                      errorWidget: (_, __, ___) => _emojiFallback(),
                    )
                  else
                    _emojiFallback(),
                  if (!offer.isUnlimited)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: offer.hasSpots
                              ? const Color(0xFFF5197F)
                              : const Color(0xFF6B7385),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          offer.hasSpots
                              ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''}'
                              : 'Complet',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (offer.isUnlimited)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17102B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '∞ ILLIMITÉ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE8B54B),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.businessName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF5197F),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101B33),
                      height: 1.2,
                    ),
                  ),
                  if (offer.businessAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      offer.businessAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7385),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiFallback() {
    return ColoredBox(
      color: const Color(0xFFEFE6D6),
      child: Center(
        child: Text(
          offer.emoji.isNotEmpty ? offer.emoji : '🎁',
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
