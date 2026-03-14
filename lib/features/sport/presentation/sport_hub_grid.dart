import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Page d'accueil Sport restructurée en 3 sections :
/// Matchs | Événements | Où pratiquer
class SportHubGrid extends ConsumerWidget {
  const SportHubGrid({super.key});

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
        // ── Section 1 : Matchs ──────────────────────────────
        _SectionHeader(title: 'Matchs', icon: Icons.sports),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SportCard(
                label: 'Rugby', image: 'assets/images/shell_sport_rugby.png',
                gradient: gradient, tag: 'Rugby', ref: ref, isScraped: true,
              ),
              _SportCard(
                label: 'Football', image: 'assets/images/shell_sport_football.png',
                gradient: gradient, tag: 'Football', ref: ref, isScraped: true,
              ),
              _SportCard(
                label: 'Basketball', image: 'assets/images/shell_sport_basketball.png',
                gradient: gradient, tag: 'Basketball', ref: ref, isScraped: true,
              ),
              _SportCard(
                label: 'Handball', image: 'assets/images/shell_sport_handball.png',
                gradient: gradient, tag: 'Handball', ref: ref, isScraped: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section 2 : Événements ──────────────────────────
        _SectionHeader(title: 'Événements', icon: Icons.event),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SportCard(
                label: 'Boxe', image: 'assets/images/pochette_boxe.png',
                gradient: gradient, tag: 'Boxe', ref: ref, isScraped: true,
              ),
              _SportCard(
                label: 'Course à pied', image: 'assets/images/pochette_courseapied.png',
                gradient: gradient, tag: 'Courses a pied', ref: ref,
              ),
              _SportCard(
                label: 'Natation', image: 'assets/images/pochette_natation.png',
                gradient: gradient, tag: 'Natation', ref: ref,
              ),
              _SportCard(
                label: 'Tennis', image: 'assets/images/pochette_tennis.png',
                gradient: gradient, tag: 'Tennis events', ref: ref,
              ),
              _SportCard(
                label: 'Stage de danse', image: 'assets/images/pochette_stagedanse.png',
                gradient: gradient, tag: 'Stage de danse', ref: ref,
              ),
              _SportCard(
                label: 'Marathon ${DateTime.now().year}',
                image: 'assets/images/pochette_course.png',
                gradient: gradient, tag: 'Marathon', ref: ref,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section 3 : Où pratiquer ────────────────────────
        _SectionHeader(title: 'Où pratiquer', icon: Icons.place),
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
              label: 'Salle de Fitness', image: 'assets/images/shell_sport_fitness.png',
              gradient: gradient, tag: 'Salle de fitness', ref: ref,
            ),
            _VenueCard(
              label: 'Salle de danse', image: 'assets/images/pochette_animation.png',
              gradient: gradient, tag: 'Danse', ref: ref,
            ),
            _VenueCard(
              label: 'Salles de boxe', image: 'assets/images/pochette_boxe.png',
              gradient: gradient, tag: 'Salles de boxe', ref: ref,
            ),
            _VenueCard(
              label: 'Terrain de football', image: 'assets/images/shell_sport_football.png',
              gradient: gradient, tag: 'Terrain de football', ref: ref,
            ),
            _VenueCard(
              label: 'Terrain de basketball', image: 'assets/images/shell_sport_basketball.png',
              gradient: gradient, tag: 'Terrain de basketball', ref: ref,
            ),
            _VenueCard(
              label: 'Piscine', image: 'assets/images/pochette_natation.png',
              gradient: gradient, tag: 'Piscine', ref: ref,
            ),
            _VenueCard(
              label: 'Golf', image: 'assets/images/pochette_Golf.png',
              gradient: gradient, tag: 'Golf', ref: ref,
            ),
            _VenueCard(
              label: 'Raquette', image: 'assets/images/pochette_autre.png',
              gradient: gradient, tag: 'Raquette', ref: ref,
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// En-tête de section — même style que "Sortir" / "Explorer" sur la home.
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

/// Card horizontale pour les sections Matchs et Événements.
class _SportCard extends StatelessWidget {
  final String label;
  final String image;
  final LinearGradient gradient;
  final String tag;
  final WidgetRef ref;
  final bool isScraped;

  const _SportCard({
    required this.label,
    required this.image,
    required this.gradient,
    required this.tag,
    required this.ref,
    this.isScraped = false,
  });

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(sportSubcategoryCountProvider(tag));
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
          onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', tag),
        ),
      ),
    );
  }
}

/// Card pour la grille "Où pratiquer".
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
    final countAsync = ref.watch(sportSubcategoryCountProvider(tag));
    return DaySubcategoryCard(
      emoji: '',
      label: label,
      image: image,
      count: countAsync.valueOrNull,
      gradient: gradient,
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', tag),
    );
  }
}
