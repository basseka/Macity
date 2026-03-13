import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Page d'accueil Tourisme restructurée en sections :
/// Se déplacer | Découvrir | Visiter
class TourismeHubGrid extends ConsumerWidget {
  const TourismeHubGrid({super.key});

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
        // ── Se déplacer ─────────────────────────────────────
        _SectionHeader(title: 'Se deplacer', icon: Icons.directions_bus_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _TourismeCard(label: 'Metro & Tramway', image: 'assets/images/carte_se_deplacer.png', gradient: gradient, tag: 'Se deplacer', ref: ref),
              _TourismeCard(label: 'Plan touristique', image: 'assets/images/carte_plan_touristique.png', gradient: gradient, tag: 'Plan touristique', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Découvrir ───────────────────────────────────────
        _SectionHeader(title: 'Decouvrir', icon: Icons.explore_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(label: 'Activites', image: 'assets/images/pochette_tourisme_toulouse.png', gradient: gradient, tag: 'Activites', ref: ref),
            _VenueCard(label: 'Visiter', image: 'assets/images/pochette_tourisme_toulouse.png', gradient: gradient, tag: 'Visiter', ref: ref),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF7B2D8E)),
    const SizedBox(width: 6),
    Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4A1259))),
  ]);
}

class _TourismeCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _TourismeCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 160, child: DaySubcategoryCard(emoji: '', label: label, image: image, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('tourisme', tag))));
  }
}

class _VenueCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _VenueCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    return DaySubcategoryCard(emoji: '', label: label, image: image, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('tourisme', tag));
  }
}
