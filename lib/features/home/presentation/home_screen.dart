import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

import 'package:pulz_app/features/home/state/banners_provider.dart';
import 'package:pulz_app/features/search/presentation/search_events_bottom_sheet.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _sortirModes = [AppMode.day, AppMode.sport, AppMode.culture, AppMode.night];
  static const _explorerModes = [AppMode.food, AppMode.family, AppMode.gaming, AppMode.tourisme];

  static const _modeBackgroundImages = <String, String>{
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.jpg',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.jpg',
    'family': 'assets/images/pochette_enfamille.jpg',
    'night': 'assets/images/home_bg_night.jpg',
    'tourisme': 'assets/images/pochette_tourime.png',
  };

  @override
  Widget build(BuildContext context) {
    // Lazy: ne precharger les banners que quand on les affiche
    ref.watch(activeBannersProvider);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F0FA),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header: logo + search + account
              _buildHeader(isLandscape),

              // Content
              Expanded(child: _buildModeGrid(isLandscape)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
      child: Column(
        children: [
          // Ligne 1 : logo + salut + compte
          Row(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(builder: (_) {
                  final prenom = ref.watch(userPrenomProvider).valueOrNull ?? '';
                  return Text(
                    prenom.isNotEmpty ? 'Salut, $prenom' : 'MaCity',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A1259),
                    ),
                  );
                }),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AccountMenu.show(context, ref),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: AccountMenu.buildButton(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 2 : barre de recherche
          GestureDetector(
            onTap: () => _openSearch(context),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: const Color(0xFF7B2D8E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rechercher un evenement, un lieu...',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeGrid(bool isLandscape) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer le ratio pour que tout tienne sans overflow
        // Espace dispo = hauteur totale - headers(2×24) - spacings(8+8+16+8+8) - padding
        final availableHeight = constraints.maxHeight;
        final gridWidth = (constraints.maxWidth - 10) / 2; // 2 columns, 10px gap
        // 4 rows total, chaque section a 2 rows
        final cardHeight = (availableHeight - 100) / 4; // 100px pour headers + spacings
        final ratio = gridWidth / cardHeight;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isLandscape ? 4 : 6),

              // Section: Sortir
              _buildSectionHeader('Sortir', Icons.celebration_outlined),
              const SizedBox(height: 6),
              _buildGridRow(_sortirModes, ratio: ratio.clamp(1.0, 1.6)),

              const SizedBox(height: 12),

              // Section: Explorer
              _buildSectionHeader('Explorer', Icons.explore_outlined),
              const SizedBox(height: 6),
              _buildGridRow(_explorerModes, ratio: ratio.clamp(1.0, 1.6)),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7B2D8E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A1259),
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow(List<AppMode> modes, {double ratio = 1.2}) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: modes.map((mode) => _buildModeCard(mode)).toList(),
    );
  }

  Widget _buildModeCard(AppMode mode) {
    final theme = ModeTheme.fromModeName(mode.name);
    final bgImage = _modeBackgroundImages[mode.name];

    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: theme.primaryColor.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(currentModeProvider.notifier).setMode(mode.name);
          context.go(mode.routePath);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (bgImage != null)
              Image.asset(
                bgImage,
                fit: BoxFit.cover,
                cacheWidth: 400,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.primaryDarkColor, theme.primaryColor],
                    ),
                  ),
                ),
              ),

            // Gradient overlay (bottom-heavy for text readability)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),

            // Text bottom-left
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode.shortLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      shadows: [const Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchEventsBottomSheet(),
    );
  }
}

/// Bottom sheet version of the mode grid (used from nav bar "Explorer" button).
class HomeScreenSheet extends ConsumerWidget {
  const HomeScreenSheet({super.key});

  static const _sortirModes = [AppMode.day, AppMode.sport, AppMode.culture, AppMode.night];
  static const _explorerModes = [AppMode.food, AppMode.family, AppMode.gaming, AppMode.tourisme];

  static const _modeBackgroundImages = <String, String>{
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.jpg',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.jpg',
    'family': 'assets/images/pochette_enfamille.jpg',
    'night': 'assets/images/home_bg_night.jpg',
    'tourisme': 'assets/images/pochette_tourime.png',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F0FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Explorer',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A1259),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Sortir', Icons.celebration_outlined),
                  const SizedBox(height: 6),
                  _buildGridRow(context, ref, _sortirModes),
                  const SizedBox(height: 12),
                  _buildSectionHeader('Explorer', Icons.explore_outlined),
                  const SizedBox(height: 6),
                  _buildGridRow(context, ref, _explorerModes),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7B2D8E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A1259),
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow(BuildContext context, WidgetRef ref, List<AppMode> modes) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: modes.map((mode) => _buildModeCard(context, ref, mode)).toList(),
    );
  }

  Widget _buildModeCard(BuildContext context, WidgetRef ref, AppMode mode) {
    final theme = ModeTheme.fromModeName(mode.name);
    final bgImage = _modeBackgroundImages[mode.name];

    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: theme.primaryColor.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(context);
          ref.read(currentModeProvider.notifier).setMode(mode.name);
          context.go(mode.routePath);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bgImage != null)
              Image.asset(
                bgImage,
                fit: BoxFit.cover,
                cacheWidth: 400,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.primaryDarkColor, theme.primaryColor],
                    ),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode.shortLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      shadows: [const Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
