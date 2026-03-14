import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';

/// Page d'accueil Culture restructurée en sections :
/// À venir | Spectacles & sorties | Lieux à découvrir
class CultureHubGrid extends ConsumerWidget {
  const CultureHubGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // ── Card À venir (prominente) ───────────────────────
        _AvenirCard(gradient: gradient, ref: ref),

        const SizedBox(height: 20),

        // ── Section 1 : Spectacles & sorties ────────────────
        _SectionHeader(title: 'Spectacles & sorties', icon: Icons.theater_comedy_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CultureCard(
                label: 'Theatre', image: 'assets/images/pochette_theatre.png',
                gradient: gradient, tag: 'Theatre', ref: ref, isScraped: true,
              ),
              _CultureCard(
                label: 'Exposition', image: 'assets/images/pochette_exposition.png',
                gradient: gradient, tag: 'Exposition', ref: ref, isScraped: true,
              ),
              _CultureCard(
                label: 'Visites guidees', image: 'assets/images/pochette_visite.png',
                gradient: gradient, tag: 'Visites guidees', ref: ref, isScraped: true,
              ),
              _CultureCard(
                label: 'Danse', image: 'assets/images/pochette_animation.png',
                gradient: gradient, tag: 'Danse', ref: ref,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section 2 : Lieux à découvrir ───────────────────
        _SectionHeader(title: 'Lieux a decouvrir', icon: Icons.account_balance_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(
              label: 'Musee', image: 'assets/images/pochette_musee.png',
              gradient: gradient, tag: 'Musee', ref: ref,
            ),
            _VenueCard(
              label: 'Monument historique', image: 'assets/images/pochette_monument.png',
              gradient: gradient, tag: 'Monument historique', ref: ref,
            ),
            _VenueCard(
              label: 'Bibliotheque', image: 'assets/images/pochette_bibliotheque.png',
              gradient: gradient, tag: 'Bibliotheque', ref: ref,
            ),
            _VenueCard(
              label: "Galerie d'art", image: 'assets/images/pochette_culture_art.png',
              gradient: gradient, tag: "Galerie d'art", ref: ref,
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Card "À venir" — accès rapide aux événements culturels du moment.
class _AvenirCard extends StatelessWidget {
  final LinearGradient gradient;
  final WidgetRef ref;

  const _AvenirCard({required this.gradient, required this.ref});

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(cultureCategoryCountProvider('A venir'));
    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('culture', 'A venir'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/pochette_cettesemaine.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Overlay sombre
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            // Scraper badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, size: 10, color: Colors.white),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A venir',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Spectacles, expos, visites...',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (countAsync.valueOrNull != null && countAsync.valueOrNull! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${countAsync.valueOrNull}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête de section — même style que la home.
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7B2D8E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A1259),
          ),
        ),
      ],
    );
  }
}

/// Card horizontale pour la section Spectacles & sorties.
class _CultureCard extends StatelessWidget {
  final String label;
  final String image;
  final LinearGradient gradient;
  final String tag;
  final WidgetRef ref;
  final bool isScraped;

  const _CultureCard({
    required this.label,
    required this.image,
    required this.gradient,
    required this.tag,
    required this.ref,
    this.isScraped = false,
  });

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(cultureCategoryCountProvider(tag));
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 130,
        child: DaySubcategoryCard(
          emoji: '',
          label: label,
          image: image,
          count: countAsync.valueOrNull,
          gradient: gradient,
          isScraped: isScraped,
          onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('culture', tag),
        ),
      ),
    );
  }
}

/// Card pour la grille "Lieux à découvrir".
class _VenueCard extends StatelessWidget {
  final String label;
  final String image;
  final LinearGradient gradient;
  final String tag;
  final WidgetRef ref;

  const _VenueCard({
    required this.label,
    required this.image,
    required this.gradient,
    required this.tag,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(cultureCategoryCountProvider(tag));
    return DaySubcategoryCard(
      emoji: '',
      label: label,
      image: image,
      count: countAsync.valueOrNull,
      gradient: gradient,
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('culture', tag),
    );
  }
}
