import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';

/// Page d'accueil Food restructurée en sections :
/// À venir | Restaurants | Cafes & brunchs | Bien-être
class FoodHubGrid extends ConsumerWidget {
  const FoodHubGrid({super.key});

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

        // ── Restaurants ─────────────────────────────────────
        _SectionHeader(title: 'Restaurants', icon: Icons.restaurant_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FoodCard(label: 'Restaurant', image: 'assets/images/pochette_restaurant.png', gradient: gradient, tag: 'Restaurant', ref: ref, invalidateOnTap: true),
              _FoodCard(label: 'Guinguette', image: 'assets/images/pochette_restaurant.png', gradient: gradient, tag: 'Guinguette', ref: ref),
              _FoodCard(label: 'Buffets', image: 'assets/images/pochette_restaurant.png', gradient: gradient, tag: 'Buffets', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Cafés & brunchs ─────────────────────────────────
        _SectionHeader(title: 'Cafes & brunchs', icon: Icons.coffee_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FoodCard(label: 'Salon de the', image: 'assets/images/pochette_salondethe.png', gradient: gradient, tag: 'Salon de the', ref: ref),
              _FoodCard(label: 'Brunch', image: 'assets/images/pochette_brunch.png', gradient: gradient, tag: 'Brunch', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Bien-être & lifestyle ───────────────────────────
        _SectionHeader(title: 'Bien-etre & lifestyle', icon: Icons.spa_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(label: 'Spa & hammam', image: 'assets/images/pochette_spa&hammam.png', gradient: gradient, tag: 'Spa hammam', ref: ref),
            _VenueCard(label: 'Massage', image: 'assets/images/pochette_spa&hammam.png', gradient: gradient, tag: 'Massage', ref: ref),
            _VenueCard(label: 'Yoga & meditation', image: 'assets/images/pochette_yoga.png', gradient: gradient, tag: 'Yoga meditation', ref: ref),
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
    final countAsync = ref.watch(foodCategoryCountProvider('A venir'));
    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('food', 'A venir'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: gradient, boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Stack(children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/pochette_cettesemaine.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.45)))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('A venir', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Gastronomie, brunchs, bien-etre...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
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

class _FoodCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  final bool invalidateOnTap;
  const _FoodCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref, this.invalidateOnTap = false});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(foodCategoryCountProvider(tag));
    return Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 130, child: DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () {
      if (invalidateOnTap) ref.invalidate(restaurantsSupabaseProvider);
      ref.read(modeSubcategoriesProvider.notifier).select('food', tag);
    })));
  }
}

class _VenueCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _VenueCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(foodCategoryCountProvider(tag));
    return DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('food', tag));
  }
}
