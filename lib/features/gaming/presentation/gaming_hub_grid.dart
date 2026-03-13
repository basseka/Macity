import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/gaming/state/gaming_venues_provider.dart';

/// Page d'accueil Gaming restructurée en sections :
/// À venir | Jeux vidéo | Jeux de société | Manga & comics | Événements
class GamingHubGrid extends ConsumerWidget {
  const GamingHubGrid({super.key});

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

        // ── Jeux vidéo ──────────────────────────────────────
        _SectionHeader(title: 'Jeux video', icon: Icons.videogame_asset_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _GamingCard(label: "Salle d'arcade", image: 'assets/images/pochette_sallearcade.png', gradient: gradient, tag: 'Salle arcade', ref: ref),
              _GamingCard(label: 'Gaming cafe', image: 'assets/images/pochette_gamingcafe.png', gradient: gradient, tag: 'Gaming cafe', ref: ref),
              _GamingCard(label: 'VR & realite virtuelle', image: 'assets/images/pochette_VR.png', gradient: gradient, tag: 'Realite virtuelle VR', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Jeux de société & cartes ────────────────────────
        _SectionHeader(title: 'Jeux de societe & cartes', icon: Icons.casino_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _GamingCard(label: 'Bar a jeux', image: 'assets/images/pochette_barajeux.png', gradient: gradient, tag: 'Bar a jeux', ref: ref),
              _GamingCard(label: 'Boutique jeux', image: 'assets/images/pochette_gaming.png', gradient: gradient, tag: 'Boutique jeux', ref: ref),
              _GamingCard(label: 'Escape game', image: 'assets/images/pochette_escapegame.png', gradient: gradient, tag: 'Escape game', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Manga, comics & BD ──────────────────────────────
        _SectionHeader(title: 'Manga, comics & BD', icon: Icons.menu_book_outlined),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _GamingCard(label: 'Boutique manga', image: 'assets/images/pochette_boutiquemanga.png', gradient: gradient, tag: 'Boutique manga', ref: ref),
              _GamingCard(label: 'Comics & BD', image: 'assets/images/pochette_default.png', gradient: gradient, tag: 'Comics BD', ref: ref),
              _GamingCard(label: 'Figurines & goodies', image: 'assets/images/pochette_default.png', gradient: gradient, tag: 'Figurines goodies', ref: ref),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Événements & conventions ────────────────────────
        _SectionHeader(title: 'Evenements & conventions', icon: Icons.event_outlined),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _VenueCard(label: 'Convention & salon', image: 'assets/images/pochette_default.png', gradient: gradient, tag: 'Convention salon geek', ref: ref),
            _VenueCard(label: 'Tournoi e-sport', image: 'assets/images/pochette_gaming.png', gradient: gradient, tag: 'Tournoi esport', ref: ref),
            _VenueCard(label: 'Cosplay', image: 'assets/images/pochette_cosplay.png', gradient: gradient, tag: 'Cosplay', ref: ref),
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
    final countAsync = ref.watch(gamingCategoryCountProvider('A venir'));
    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('gaming', 'A venir'),
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
              Text('Tournois, conventions, events...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
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

class _GamingCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _GamingCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(gamingCategoryCountProvider(tag));
    return Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 130, child: DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('gaming', tag))));
  }
}

class _VenueCard extends StatelessWidget {
  final String label, image, tag;
  final LinearGradient gradient;
  final WidgetRef ref;
  const _VenueCard({required this.label, required this.image, required this.gradient, required this.tag, required this.ref});
  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(gamingCategoryCountProvider(tag));
    return DaySubcategoryCard(emoji: '', label: label, image: image, count: countAsync.valueOrNull, gradient: gradient, onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('gaming', tag));
  }
}
