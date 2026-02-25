import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/home/state/banners_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Pre-charger le scraping des clubs des le lancement.
    ref.read(nineClubEventsProvider);
    ref.read(etoileEventsProvider);
    // Pre-charger les bannieres pour que le carrousel ait les donnees pretes.
    ref.watch(activeBannersProvider);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F0FA),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // Logo + search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 14,
                    height: 14,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'MaCity',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey.shade400, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Trouve un evenement',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => const AppBottomNavBar().showAddEvent(context, ref),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isLandscape ? 6 : 8),


                  // Mode cards (vertical stack)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: AppMode.order.map((mode) {
                        return _buildModeCard(mode, compact: isLandscape);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
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

  static const _modeBackgroundImages = <String, String>{
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.png',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.png',
    'family': 'assets/images/pochette_enfamille.png',
    'night': 'assets/images/home_bg_night.png',
  };

  Widget _buildModeCard(AppMode mode, {bool compact = false}) {
    final theme = ModeTheme.fromModeName(mode.name);
    final bgImage = _modeBackgroundImages[mode.name];

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0x207B2D8E),
          onTap: () {
            ref.read(currentModeProvider.notifier).setMode(mode.name);
            context.go(mode.routePath);
          },
          child: Container(
            height: compact ? 125 : 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: bgImage == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.primaryDarkColor, theme.primaryColor],
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // Background image
                if (bgImage != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        bgImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                // Dark overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mode.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 14, fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

