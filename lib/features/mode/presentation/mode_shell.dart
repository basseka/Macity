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
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/mode_video_banner.dart';
import 'package:pulz_app/features/search/presentation/search_events_bottom_sheet.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/home/presentation/widgets/banner_carousel.dart';
import 'package:pulz_app/features/notifications/presentation/mairie_notifications_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/my_publications_sheet.dart';
import 'package:pulz_app/core/services/activity_service.dart';

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
      ActivityService.instance.modeView(mode: next);
    });

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Fête de la Musique → plein écran, pas de shell chrome
    final isFeteMusique = ref.watch(currentModeProvider) == 'day' &&
        ref.watch(modeSubcategoriesProvider)['day'] == 'Fete musique';

    // Cartes sport venues → plein écran
    final sportSub = ref.watch(modeSubcategoriesProvider)['sport'] ?? '';
    final isSportMap = ref.watch(currentModeProvider) == 'sport' &&
        sportSub.endsWith(' carte');

    // Tourisme carte interactive → plein écran
    final tourismeSub = ref.watch(modeSubcategoriesProvider)['tourisme'] ?? '';
    final isTourismeMap = ref.watch(currentModeProvider) == 'tourisme' &&
        (tourismeSub == 'Plan touristique' || tourismeSub == 'Se deplacer');

    final isFullscreen = isFeteMusique || isSportMap || isTourismeMap;

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

        // Tourisme : sous-carte de Visiter → retour au hub Visiter
        if (currentMode == 'tourisme') {
          const visiterChildren = {
            'City tour', 'Tuk-tuk', 'Petit Train',
            'La maison de la violette', 'Le Canal',
          };
          if (subcategory != null && visiterChildren.contains(subcategory)) {
            ref.read(modeSubcategoriesProvider.notifier).select('tourisme', 'Visiter');
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
      child: isFullscreen
        ? Scaffold(
            backgroundColor: modeTheme.backgroundColor,
            body: SafeArea(child: child),
          )
        : Scaffold(
      backgroundColor: modeTheme.backgroundColor,
      body: SwipeDetector(
        onSwipeLeft: () => ref.read(currentModeProvider.notifier).nextMode(),
        onSwipeRight: () => ref.read(currentModeProvider.notifier).previousMode(),
        child: SafeArea(
          bottom: false,
          child: Column(
          children: [
            // Logo + ville + compte
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: isLandscape ? 4 : 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CityPickerBottomSheet(),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.watch(selectedCityProvider),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AccountMenu.show(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: AccountMenu.buildButton(ref: ref),
                    ),
                  ),
                ],
              ),
            ),
            // Menu hamburger + Barre de recherche
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 2 : 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showCategoryMenu(context, ref),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Icon(Icons.menu, color: Colors.grey.shade600, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search, color: Colors.grey.shade400, size: 16),
                            const SizedBox(width: 6),
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

            // Subcategory breadcrumb
            _SubcategoryBreadcrumb(isLandscape: isLandscape),

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

  void _showCategoryMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Modes
              ...AppMode.order.map((mode) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  mode.label,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 3;
                  Navigator.pop(ctx);
                  ref.read(currentModeProvider.notifier).setMode(mode.name);
                  context.go(mode.routePath);
                },
              )),
              const Divider(color: Colors.white24, height: 24),
              // Liens supplementaires
              ListTile(
                dense: true,
                leading: const Icon(Icons.article, color: Colors.purpleAccent, size: 18),
                title: const Text('Mes publications', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  Navigator.pop(ctx);
                  MyPublicationsSheet.show(context);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                title: const Text('Mes favoris', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 4;
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const LikedPlacesBottomSheet(),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.card_giftcard, color: Colors.amber, size: 18),
                title: const Text('Offres', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 2;
                  Navigator.pop(ctx);
                  BannerCarouselDialog.show(context);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance, color: Colors.blueAccent, size: 18),
                title: const Text('Mairies', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 1;
                  Navigator.pop(ctx);
                  MairieNotificationsSheet.show(context);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.tune, color: Colors.tealAccent, size: 18),
                title: const Text('Preferences', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  Navigator.pop(ctx);
                  NotificationPrefsSheet.show(context);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.login, color: Colors.orangeAccent, size: 18),
                title: const Text('Connexion', style: TextStyle(color: Colors.white, fontSize: 10)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ProLoginSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
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
    AppMode.sport: 'assets/images/home_bg_sport.jpg',
    AppMode.culture: 'assets/images/pochette_culture_art.png',
    AppMode.family: 'assets/images/pochette_enfamille.jpg',
    AppMode.food: 'assets/images/pochette_food.png',
    AppMode.gaming: 'assets/images/pochette_gaming.jpg',
    AppMode.night: 'assets/images/home_bg_night.jpg',
    AppMode.tourisme: 'assets/images/pochette_tourime.png',
  };

  // Short labels now come from AppMode.shortLabel

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
            final label = m.shortLabel;

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
                          cacheWidth: 300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
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

class _SubcategoryBreadcrumb extends ConsumerWidget {
  final bool isLandscape;

  const _SubcategoryBreadcrumb({required this.isLandscape});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final subcategory = ref.watch(modeSubcategoriesProvider)[currentMode];
    final modeTheme = ref.watch(modeThemeProvider);

    if (subcategory == null) return const SizedBox.shrink();

    final mode = AppMode.fromName(currentMode);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 2 : 6,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select(currentMode, null);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 12,
                  color: modeTheme.primaryColor,
                ),
                const SizedBox(width: 2),
                Text(
                  mode.shortLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: modeTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: modeTheme.chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subcategory,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: modeTheme.primaryDarkColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
