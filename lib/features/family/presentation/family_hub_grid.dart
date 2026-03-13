import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';

/// Page d'accueil Famille restructurée en sections :
/// À venir | Parcs & jeux | Loisirs | Culture | Restauration
class FamilyHubGrid extends ConsumerWidget {
  const FamilyHubGrid({super.key});

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
        _AvenirBanner(gradient: gradient, ref: ref),
        const SizedBox(height: 20),

        // ── Parcs & jeux ────────────────────────────────────
        _SectionHeader(title: 'Parcs & jeux', icon: Icons.park_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Card(label: "Parc d'attractions", image: 'assets/images/pochette_parc_attraction.png', gradient: gradient, tag: "Parc d'attractions", ref: ref),
              _Card(label: 'Aire de jeux', image: 'assets/images/pochette_enfamille.png', gradient: gradient, tag: 'Aire de jeux', ref: ref),
              _Card(label: 'Parc animalier', image: 'assets/images/pochette_parc_animalier.png', gradient: gradient, tag: 'Parc animalier', ref: ref),
              _Card(label: 'Ferme pedagogique', image: 'assets/images/pochette_enfamille.png', gradient: gradient, tag: 'Ferme pedagogique', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Loisirs ─────────────────────────────────────────
        _SectionHeader(title: 'Loisirs', icon: Icons.sports_esports_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Card(label: 'Cinema', image: 'assets/images/pochette_spectacle.png', gradient: gradient, tag: 'Cinema', ref: ref),
              _Card(label: 'Bowling', image: 'assets/images/pochette_enfamille.png', gradient: gradient, tag: 'Bowling', ref: ref),
              _Card(label: 'Laser game', image: 'assets/images/pochette_enfamille.png', gradient: gradient, tag: 'Laser game', ref: ref),
              _Card(label: 'Escape game', image: 'assets/images/pochette_gaming.png', gradient: gradient, tag: 'Escape game', ref: ref),
              _Card(label: 'Patinoire', image: 'assets/images/pochette_enfamille.png', gradient: gradient, tag: 'Patinoire', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Culture & restauration ──────────────────────────
        _SectionHeader(title: 'Culture & restauration', icon: Icons.restaurant_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(label: 'Aquarium', image: 'assets/images/pochette_parc_animalier.png', gradient: gradient, tag: 'Aquarium', ref: ref),
            _VenueCard(label: 'Restaurant familial', image: 'assets/images/pochette_restaurant.png', gradient: gradient, tag: 'Restaurant familial', ref: ref),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AvenirBanner extends StatelessWidget {
  final LinearGradient gradient;
  final WidgetRef ref;
  const _AvenirBanner({required this.gradient, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(familyCategoryCountProvider('A venir'));
    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('family', 'A venir'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: gradient, boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Stack(children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/pochette_default.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.45)))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('A venir', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Sorties en famille a venir...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
            ])),
            if (countAsync.valueOrNull != null && countAsync.valueOrNull! > 0)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                child: Text('${countAsync.valueOrNull}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
          ])),
        ]),
      ),
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

class _Card extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _Card({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(familyCategoryCountProvider(tag));
    return Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 130, child: DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('family', tag))));
  }
}

class _VenueCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _VenueCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(familyCategoryCountProvider(tag));
    return DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('family', tag));
  }
}
