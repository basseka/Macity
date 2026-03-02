import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/presentation/widgets/swipe_detector.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/widgets/mode_video_banner.dart';
import 'package:pulz_app/features/search/presentation/search_events_bottom_sheet.dart';

class ModeShell extends ConsumerWidget {
  final Widget child;

  const ModeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    // Navigate to the correct route when mode changes
    ref.listen<String>(currentModeProvider, (previous, next) {
      // Remettre la grille de rubriques a chaque changement de shell
      ref.read(modeSubcategoriesProvider.notifier).select(next, null);
      final newMode = AppMode.fromName(next);
      context.go(newMode.routePath);
    });

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Fête de la Musique → plein écran, pas de shell chrome
    final isFeteMusique = ref.watch(currentModeProvider) == 'day' &&
        ref.watch(modeSubcategoriesProvider)['day'] == 'Fete musique';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // Navigation interne : remonter d'un niveau avant de quitter
        final currentMode = ref.read(currentModeProvider);
        final subcategory = ref.read(modeSubcategoriesProvider)[currentMode];

        if (currentMode == 'day' && subcategory == 'Concert') {
          final venue = ref.read(selectedConcertVenueProvider);
          if (venue != null) {
            // Events d'une salle → retour à la grille des salles
            ref.read(selectedConcertVenueProvider.notifier).state = null;
            return;
          }
        }

        if (subcategory != null) {
          // Sous-catégorie sélectionnée → retour à la grille des rubriques
          ref.read(modeSubcategoriesProvider.notifier).select(currentMode, null);
          ref.read(dateRangeFilterProvider.notifier).state =
              const DateRangeFilter();
          return;
        }

        // Aucune navigation interne → retour à l'accueil
        context.go('/home');
      },
      child: isFeteMusique
        ? Scaffold(
            backgroundColor: modeTheme.backgroundColor,
            body: SafeArea(child: child),
          )
        : Scaffold(
      backgroundColor: modeTheme.backgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
      body: SwipeDetector(
        onSwipeLeft: () => ref.read(currentModeProvider.notifier).nextMode(),
        onSwipeRight: () => ref.read(currentModeProvider.notifier).previousMode(),
        child: SafeArea(
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
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SearchEventsBottomSheet(),
                        );
                      },
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
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
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
            // Mode bubble bar
            _ModeBubbleBar(isLandscape: isLandscape),
            // Indicator bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: modeTheme.chipColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            // Video banner (hidden in landscape and for Fete musique map)
            if (!isLandscape &&
                !(ref.watch(currentModeProvider) == 'day' &&
                    ref.watch(modeSubcategoriesProvider)['day'] == 'Fete musique'))
              const ModeVideoBanner(),

            // Child content (mode screen)
            Expanded(child: child),
          ],
        ),
        ),
      ),
    ),
    );
  }
}

class _ModeBubbleBar extends ConsumerStatefulWidget {
  final bool isLandscape;

  const _ModeBubbleBar({required this.isLandscape});

  @override
  ConsumerState<_ModeBubbleBar> createState() => _ModeBubbleBarState();
}

class _ModeBubbleBarState extends ConsumerState<_ModeBubbleBar> {
  final ScrollController _scrollController = ScrollController();

  static const _bubbleSize = 62.0;

  static const _modeImages = {
    AppMode.day: 'assets/images/pochette_concert.png',
    AppMode.sport: 'assets/images/home_bg_sport.png',
    AppMode.culture: 'assets/images/pochette_culture_art.png',
    AppMode.family: 'assets/images/pochette_enfamille.png',
    AppMode.food: 'assets/images/pochette_food.png',
    AppMode.gaming: 'assets/images/pochette_gaming.png',
    AppMode.night: 'assets/images/home_bg_night.png',
  };

  static const _modeShortLabels = {
    AppMode.day: 'Concert',
    AppMode.sport: 'Sport',
    AppMode.culture: 'Culture',
    AppMode.family: 'Famille',
    AppMode.food: 'Food',
    AppMode.gaming: 'Gaming',
    AppMode.night: 'Nuit',
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerActiveBubble(int activeIndex) {
    if (!_scrollController.hasClients) return;
    const bubbleWidth = 74.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (activeIndex * bubbleWidth) - (screenWidth / 2) + (bubbleWidth / 2);
    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final mode = AppMode.fromName(currentMode);
    final modeIndex = AppMode.order.indexOf(mode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerActiveBubble(modeIndex);
    });

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: widget.isLandscape ? 2 : 4),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AppMode.order.asMap().entries.map((entry) {
            final index = entry.key;
            final m = entry.value;
            final isActive = index == modeIndex;
            final image = _modeImages[m]!;
            final label = _modeShortLabels[m]!;

            return GestureDetector(
              onTap: () => ref.read(currentModeProvider.notifier).setMode(m.name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _bubbleSize,
                      height: _bubbleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? LinearGradient(
                                colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                              )
                            : null,
                        color: isActive ? null : Colors.grey.shade300,
                      ),
                      padding: EdgeInsets.all(isActive ? 3 : 1.5),
                      child: ClipOval(
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? modeTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
