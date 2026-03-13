import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';

/// Page d'accueil Nuit restructurée en sections :
/// À venir | Bars & vie nocturne | Commerces de nuit | Hébergement
class NightHubGrid extends ConsumerWidget {
  const NightHubGrid({super.key});

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
        // ── Card À venir ────────────────────────────────────
        _AvenirBanner(gradient: gradient, ref: ref),

        const SizedBox(height: 20),

        // ── Section 1 : Bars & vie nocturne ─────────────────
        _SectionHeader(title: 'Bars & vie nocturne', icon: Icons.local_bar_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _NightCard(label: 'Bar de nuit', image: 'assets/images/pochette_pub.png', gradient: gradient, tag: 'Bar de nuit', ref: ref),
              _NightCard(label: 'Club / Disco', image: 'assets/images/pochette_discotheque.png', gradient: gradient, tag: 'Club Discotheque', ref: ref),
              _NightCard(label: 'Bar a cocktails', image: 'assets/images/pochette_pub.png', gradient: gradient, tag: 'Bar a cocktails', ref: ref),
              _NightCard(label: 'Bar a chicha', image: 'assets/images/pochette_chicha.png', gradient: gradient, tag: 'Bar a chicha', ref: ref),
              _NightCard(label: 'Pub', image: 'assets/images/pochette_pub.png', gradient: gradient, tag: 'Pub', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section 2 : Commerces de nuit ───────────────────
        _SectionHeader(title: 'Commerces ouverts la nuit', icon: Icons.store_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _NightCard(label: 'Epicerie de nuit', image: 'assets/images/pochette_tabac.png', gradient: gradient, tag: 'Epicerie de nuit', ref: ref),
              _NightCard(label: 'SOS Apero', image: 'assets/images/pochette_default.png', gradient: gradient, tag: 'SOS Apero', ref: ref),
              _NightCard(label: 'Tabac de nuit', image: 'assets/images/pochette_tabac.png', gradient: gradient, tag: 'Tabac de nuit', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section 3 : Hébergement ─────────────────────────
        _SectionHeader(title: 'Hebergement', icon: Icons.hotel_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(label: 'Hotel', image: 'assets/images/pochette_hotel.png', gradient: gradient, tag: 'Hotel', ref: ref),
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
    final countAsync = ref.watch(nightCategoryCountProvider('A venir'));
    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('night', 'A venir'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/pochette_default.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
            Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.45)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('A venir', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Soirees, events nocturnes...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                  ])),
                  if (countAsync.valueOrNull != null && countAsync.valueOrNull! > 0)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                      child: Text('${countAsync.valueOrNull}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF7B2D8E)),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4A1259))),
    ]);
  }
}

class _NightCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _NightCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(nightCategoryCountProvider(tag));
    return Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 130, child: DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('night', tag))));
  }
}

class _VenueCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _VenueCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(nightCategoryCountProvider(tag));
    return DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('night', tag));
  }
}
