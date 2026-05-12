import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_city_header.dart';
import 'package:pulz_app/features/home/presentation/widgets/banner_carousel.dart';
import 'package:pulz_app/features/home/state/search_intent_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Ecran "Explorer" — handoff coherence v1.0 (Avril 2026).
///
/// Layout :
///  1. CityHeader (logo + Ta ville + ville + avatar)
///  2. SectionHeader "✦ Toutes les *rubriques*"
///  3. Grille 2 col de 8 cards rubriques
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: EditorialColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: EditorialCityHeader()),
            // Header "Toutes les offres" avec bouton cadeau qui ouvre le
            // carrousel d'offres / banners.
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
                              text: 'Toutes les ',
                              style: EditorialText.displayTitle()
                                  .copyWith(fontSize: 24),
                            ),
                            TextSpan(
                              text: 'offres',
                              style: EditorialText.sectionItalic(
                                color: EditorialColors.gold,
                              ).copyWith(fontSize: 24),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GiftButton(
                      onTap: () => BannerCarouselDialog.show(context),
                    ),
                  ],
                ),
              ),
            ),
            // Barre de recherche : sur tap on bascule sur /home en mode
            // recherche (FeedScreen consomme searchIntentProvider).
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EditorialSpacing.screen,
                  0,
                  EditorialSpacing.screen,
                  EditorialSpacing.md,
                ),
                child: _ExplorerSearchBar(
                  onTap: () {
                    ref.read(searchIntentProvider.notifier).state = true;
                    ref.read(navBarIndexProvider.notifier).state = 0;
                    context.go('/home');
                  },
                ),
              ),
            ),
            // Grille edge-to-edge : affiches rectangulaires (pas de radius),
            // separateur blanc 1px entre les affiches. Bordure exterieure
            // blanche dessinee par la SliverToBoxAdapter wrappante.
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 1),
                    left: BorderSide(color: Colors.white, width: 1),
                    right: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: AppMode.order.length,
                  itemBuilder: (context, i) =>
                      _buildModeCard(context, ref, AppMode.order[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: EditorialSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, WidgetRef ref, AppMode mode) {
    final meta = _modeMeta[mode]!;
    return _ExplorerPosterCard(
      label: meta.title,
      kicker: meta.section,
      imageTag: meta.imageTag,
      imageUrl: _modeImage[mode],
      accent: meta.accent,
      onTap: () {
        ref.read(currentModeProvider.notifier).setMode(mode.name);
        context.push(mode.routePath);
      },
    );
  }

  // ─── Metadata par mode ────────────────────────────────────────────
  static const _modeMeta = <AppMode, _ModeMeta>{
    AppMode.day: _ModeMeta(
      section: 'Musique',
      title: 'Scène',
      imageTag: 'CONCERT',
      accent: EditorialColors.gold,
    ),
    AppMode.night: _ModeMeta(
      section: 'After',
      title: 'Nuit',
      imageTag: 'NIGHT CLUB',
      accent: EditorialColors.cyan,
    ),
    AppMode.food: _ModeMeta(
      section: 'Plaisirs',
      title: 'Food',
      imageTag: 'FOOD',
      accent: EditorialColors.orange,
    ),
    AppMode.sport: _ModeMeta(
      section: 'Active',
      title: 'Sport',
      imageTag: 'SPORT',
      accent: EditorialColors.green,
    ),
    AppMode.culture: _ModeMeta(
      section: 'Culture',
      title: 'Culture',
      imageTag: 'MUSEUM',
      accent: EditorialColors.cyan,
    ),
    AppMode.family: _ModeMeta(
      section: 'Famille',
      title: 'Famille',
      imageTag: 'FAMILY',
      accent: EditorialColors.orange,
    ),
    AppMode.gaming: _ModeMeta(
      section: 'Joueurs',
      title: 'Gaming',
      imageTag: 'GAMING',
      accent: EditorialColors.green,
    ),
    AppMode.tourisme: _ModeMeta(
      section: 'Visite',
      title: 'Tourisme',
      imageTag: 'TOURISME',
      accent: EditorialColors.gold,
    ),
  };

  static const _modeImage = <AppMode, String>{
    AppMode.day: 'assets/images/pochette_concert.png',
    AppMode.sport: 'assets/images/home_bg_sport.jpg',
    AppMode.culture: 'assets/images/pochette_culture_art.png',
    AppMode.food: 'assets/images/pochette_food.png',
    AppMode.gaming: 'assets/images/pochette_gaming.jpg',
    AppMode.family: 'assets/images/pochette_enfamille.jpg',
    AppMode.night: 'assets/images/home_bg_night.jpg',
    AppMode.tourisme: 'assets/images/pochette_tourime.png',
  };
}

class _ModeMeta {
  final String section;
  final String title;
  final String imageTag;
  final Color accent;

  const _ModeMeta({
    required this.section,
    required this.title,
    required this.imageTag,
    required this.accent,
  });
}

/// Carte rubrique style affiche : image plein cadre rectangulaire (sans
/// radius), overlay degrade sombre en bas + titre/kicker en sur-impression,
/// tag mono en coin haut-gauche. Bordure droite + basse 1px blanche pour
/// dessiner le quadrillage (le grid parent porte les bordures top + left +
/// right exterieures).
class _ExplorerPosterCard extends StatelessWidget {
  final String label;
  final String kicker;
  final String? imageTag;
  final String? imageUrl;
  final Color accent;
  final VoidCallback onTap;

  const _ExplorerPosterCard({
    required this.label,
    required this.kicker,
    this.imageTag,
    this.imageUrl,
    required this.accent,
    required this.onTap,
  });

  Widget _buildImage() {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.6),
              accent.withValues(alpha: 0.3),
            ],
          ),
        ),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: EditorialColors.surface),
        errorWidget: (_, __, ___) => Container(color: EditorialColors.surface),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      cacheWidth: 400,
      errorBuilder: (_, __, ___) => Container(color: EditorialColors.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.white, width: 1),
            bottom: BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              // Degrade sombre du bas pour lisibilite du titre
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              // Tag mono en coin haut-gauche (optionnel)
              if (imageTag != null && imageTag!.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Text(
                      imageTag!.toUpperCase(),
                      style: GoogleFonts.geistMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Kicker + titre en bas
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kicker.toUpperCase(),
                      style: GoogleFonts.geistMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de recherche style FeedScreen (look identique pour cohesion). Sur
/// tap, declenche le mode recherche dans FeedScreen via searchIntentProvider
/// puis navigue vers /home.
class _ExplorerSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _ExplorerSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: AppColors.magenta, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rechercher un evenement, un lieu...',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.textFaint,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

/// Bouton cadeau circulaire avec gradient magenta→gold + glow.
/// Ouvre le carrousel des offres au tap.
class _GiftButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GiftButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [EditorialColors.magenta, EditorialColors.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: EditorialColors.magenta.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.card_giftcard,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }
}
