import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/home/state/banners_provider.dart';
import 'package:pulz_app/features/admin/presentation/admin_add_etablissement_sheet.dart';
import 'package:pulz_app/features/search/presentation/search_events_bottom_sheet.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  static const _sortirModes = [AppMode.day, AppMode.sport, AppMode.culture, AppMode.night];
  static const _explorerModes = [AppMode.food, AppMode.family, AppMode.gaming, AppMode.tourisme];

  static const _modeBackgroundImages = <String, String>{
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.png',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.png',
    'family': 'assets/images/pochette_enfamille.png',
    'night': 'assets/images/home_bg_night.png',
    'tourisme': 'assets/images/pochette_tourisme_toulouse.png',
  };

  @override
  Widget build(BuildContext context) {
    ref.read(nightScrapedEventsProvider);
    ref.watch(activeBannersProvider);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final city = ref.watch(selectedCityProvider);
    final isToulouse = city.toLowerCase() == 'toulouse';

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
              Expanded(
                child: isToulouse
                    ? _buildModeGrid(isLandscape)
                    : _buildCityPlaceholder(city),
              ),
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
              GestureDetector(
                onTap: _handleLogoTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
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
                onTap: () => AccountMenu.show(context, ref),
                child: AccountMenu.buildButton(),
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

  Widget _buildCityPlaceholder(String city) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Ville en cours de construction...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$city arrive bientot !',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTap != null && now.difference(_lastLogoTap!).inMilliseconds > 1500) {
      _logoTapCount = 0;
    }
    _lastLogoTap = now;
    _logoTapCount++;
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      AdminAddEtablissementSheet.show(context);
    }
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
