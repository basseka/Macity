import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/services/deep_link_service.dart';
import 'package:pulz_app/features/home/presentation/widgets/boosted_events_carousel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';
import 'package:pulz_app/features/admin/presentation/widgets/admin_pin_gesture.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/home/state/paginated_feed_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';
import 'package:pulz_app/features/search/data/unified_search_service.dart';
import 'package:pulz_app/features/search/domain/search_result.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/home/presentation/widgets/banner_carousel.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:pulz_app/features/home/state/feed_video_controller.dart';
import 'package:pulz_app/features/notifications/presentation/mairie_notifications_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/my_publications_sheet.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/animated_ad_banner.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/reported_events/presentation/snap_camera_screen.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_carousel.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_legend.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_map.dart';

final _foodScrapedProvider = FutureProvider.family<List<Event>, String>((ref, city) async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ScrapedEventsSupabaseService().fetchEvents(rubrique: 'food', dateGte: today, ville: city);
});

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const _accentColor = Color(0xFFE91E8C);

  // ── Filtres hierarchiques (2 niveaux) ────────────────────────────
  // Niveau 1 : onglet (Tout = null, ou un des _tabs)
  // Niveau 2 : sous-filtre optionnel du tab actif
  static const _tabs = <String>['En Scène', 'Event', 'Clubbing'];
  static const _subFilters = <String, List<String>>{
    'En Scène': ['Concerts', 'Théâtre', 'One-man-show', 'Danse', 'Comédie musicale', 'Opéra', 'Humour'],
    'Event': ['Salon/expo', 'Soirée', 'Famille', 'Food', 'Sport'],
    'Clubbing': ['Bar', 'Club & Disco'],
  };
  // Mots-cles matches contre event.categorie/type/titre (toLowerCase)
  static const _subKeywords = <String, List<String>>{
    'Concerts': ['concert', 'musique'],
    'Théâtre': ['theatre', 'théâtre'],
    'One-man-show': ['one-man', 'one man', 'stand-up', 'stand up'],
    'Danse': ['danse', 'ballet'],
    'Comédie musicale': ['comedie musicale', 'comédie musicale'],
    'Opéra': ['opera', 'opéra'],
    'Humour': ['humour'],
    'Salon/expo': ['salon', 'expo', 'foire', 'vernissage'],
    'Soirée': ['soiree', 'soirée'],
    'Sport': ['sport', 'match', 'tournoi', 'competition', 'compétition'],
    'Bar': ['bar', 'pub', 'cocktail'],
    'Club & Disco': ['club', 'disco', 'dj', 'boite de nuit', 'boîte de nuit'],
  };
  // Keywords pour "En Scène" sans sous-filtre (union des sous-cats)
  static const _enSceneKeywords = <String>[
    'concert', 'musique', 'theatre', 'théâtre',
    'one-man', 'one man', 'stand-up', 'stand up',
    'danse', 'ballet',
    'comedie musicale', 'comédie musicale',
    'opera', 'opéra', 'humour',
  ];

  String? _activeTab; // null = Tout
  String? _activeSub; // null = pas de sous-filtre

  // Search state
  final _searchController = TextEditingController();
  final _searchService = UnifiedSearchService();
  final _feedScrollController = ScrollController();
  bool _isSearching = false;
  bool _searchLoading = false;
  List<SearchResult>? _searchResults;
  String? _aiMessage;
  List<Map<String, dynamic>>? _aiResults;

  @override
  void initState() {
    super.initState();
    // Afficher un event deep link en attente, après que le feed soit rendu
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) deepLinkShowPending();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _feedScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = null;
        _aiMessage = null;
        _aiResults = null;
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_searchController.text.trim() != query.trim()) return;
      _doSearch(query.trim());
    });
  }

  Future<void> _doSearch(String query) async {
    try {
      final ville = ref.read(selectedCityProvider);

      // Recherche classique
      final resultsFuture = _searchService.search(query, ville: ville);

      // Recherche IA si la requete ressemble a du langage naturel (3+ mots)
      final words = query.split(' ').where((w) => w.length > 1).length;
      Future<Map<String, dynamic>?>? aiFuture;
      if (words >= 2) {
        aiFuture = _searchAI(query, ville);
      }

      final results = await resultsFuture;
      final aiData = await aiFuture;

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _aiMessage = aiData?['message'] as String?;
        _aiResults = (aiData?['results'] as List?)?.cast<Map<String, dynamic>>();
        _searchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _aiMessage = null;
        _aiResults = null;
        _searchLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _searchAI(String query, String ville) async {
    try {
      final dio = DioClient.withBaseUrl(SupabaseConfig.supabaseUrl);
      final res = await dio.post(
        '/functions/v1/search-ai',
        data: {'query': query, 'ville': ville},
        options: Options(headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        }),
      );
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[search-ai] error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _searchResults = null;
          });
        } else if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false,
          child: _buildBody(context),
        ),
      ),
    );
  }

  bool get _isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (!_isSearching) _buildFilterBar(),
        if (!_isSearching) const SizedBox(height: 10),
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildFeed(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Row 1: logo + greeting + account
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
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CityPickerBottomSheet(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ref.watch(selectedCityProvider),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Builder(builder: (_) {
                final prenom = ref.watch(userPrenomProvider).valueOrNull ?? '';
                return Text(
                  prenom.isNotEmpty ? prenom : 'MaCity',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                );
              }),
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
          const SizedBox(height: 8),
          // Row 2: search bar + hamburger menu
          _isSearching
              ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nom, lieu, artiste...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: _accentColor, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                            _searchResults = null;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showCategoryMenu(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Icons.menu, color: Colors.white60, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSearching = true),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search, color: _accentColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Rechercher un evenement, un lieu...',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }

  static const _menuModes = [
    AppMode.day,
    AppMode.sport,
    AppMode.culture,
    AppMode.night,
    AppMode.food,
    AppMode.family,
    AppMode.gaming,
    AppMode.tourisme,
  ];

  void _openReportModal() {
    _openSnapCamera();
  }

  void _openVideoReport() {
    _openSnapCamera();
  }

  void _openSnapCamera() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SnapCameraScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  SliverList _buildSignalementsSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.flag, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ca bouge pres de toi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Material(
                color: const Color(0xFF7B2D8E),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _openVideoReport,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live Notif',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ReportedEventsMap(height: 280),
        ),
        const SizedBox(height: 6),
        const ReportedEventsLegend(),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: ReportedEventsCarousel(),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _showCategoryMenu(BuildContext context) {
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
              ..._menuModes.map((mode) => ListTile(
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

  Widget _buildFilterBar() {
    return Column(
      children: [
        // ── Row 1 : onglets principaux ───────────────────────
        // Hauteur augmentee a 40 pour donner une zone de tap confortable
        // (Material Design recommande 48, 40 est un bon compromis visuel).
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildChip(
                label: 'Tout',
                selected: _activeTab == null,
                onTap: () => setState(() {
                  _activeTab = null;
                  _activeSub = null;
                }),
              ),
              for (final tab in _tabs)
                _buildChip(
                  label: tab,
                  selected: _activeTab == tab,
                  onTap: () => setState(() {
                    if (_activeTab == tab) {
                      // Re-tap → retour sur Tout
                      _activeTab = null;
                      _activeSub = null;
                    } else {
                      _activeTab = tab;
                      _activeSub = null;
                    }
                  }),
                ),
            ],
          ),
        ),
        // ── Row 2 : sous-filtres (visible uniquement si tab actif) ──
        if (_activeTab != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final sub in _subFilters[_activeTab]!)
                  _buildChip(
                    label: sub,
                    selected: _activeSub == sub,
                    isSubFilter: true,
                    onTap: () => setState(() {
                      _activeSub = _activeSub == sub ? null : sub;
                    }),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isSubFilter = false,
  }) {
    // La zone de tap couvre toute la hauteur du SizedBox parent + la marge
    // droite entre chips. HitTestBehavior.opaque garantit qu'un tap sur
    // une zone transparente (entre pilule et bord) declenche bien onTap.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSubFilter ? 10 : 12,
              vertical: isSubFilter ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: selected ? _accentColor : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _accentColor : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSubFilter ? 10 : 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Matching d'un Event contre les filtres actifs.
  bool _matchesFilter(Event e) {
    if (_activeTab == null) return true;

    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    final titre = e.titre.toLowerCase();
    final rubrique = e.rubrique.toLowerCase();

    bool matchAnyKw(List<String> kws) {
      for (final kw in kws) {
        if (cat.contains(kw) || type.contains(kw) || titre.contains(kw)) return true;
      }
      return false;
    }

    switch (_activeTab) {
      case 'En Scène':
        // rubrique day ou culture
        if (rubrique != 'day' && rubrique != 'culture') return false;
        if (_activeSub == null) return matchAnyKw(_enSceneKeywords);
        return matchAnyKw(_subKeywords[_activeSub]!);

      case 'Event':
        // Gestion par sous-filtre (les Event events sont heterogenes par nature)
        if (_activeSub == null) {
          // Union : famille OU food OU salon/expo OU soiree-pas-night OU sport
          if (rubrique == 'family' || rubrique == 'food') return true;
          if (matchAnyKw(_subKeywords['Salon/expo']!)) return true;
          if (rubrique != 'night' && matchAnyKw(_subKeywords['Soirée']!)) return true;
          if (matchAnyKw(_subKeywords['Sport']!)) return true;
          return false;
        }
        switch (_activeSub) {
          case 'Famille':
            return rubrique == 'family';
          case 'Food':
            return rubrique == 'food';
          case 'Salon/expo':
            return matchAnyKw(_subKeywords['Salon/expo']!);
          case 'Soirée':
            return rubrique != 'night' && matchAnyKw(_subKeywords['Soirée']!);
          case 'Sport':
            return matchAnyKw(_subKeywords['Sport']!);
        }
        return false;

      case 'Clubbing':
        if (rubrique != 'night') return false;
        if (_activeSub == null) return true;
        return matchAnyKw(_subKeywords[_activeSub]!);
    }
    return true;
  }


  // ── Search results ──

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor),
            ),
            if (_searchController.text.split(' ').where((w) => w.length > 1).length >= 3) ...[
              const SizedBox(height: 12),
              Text('Recherche en cours...', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ],
          ],
        ),
      );
    }

    // Afficher la reponse IA si disponible
    if (_aiMessage != null && _aiMessage!.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Bulle IA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text('Pour toi', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aiMessage!,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resultats IA cliquables
          if (_aiResults != null)
            for (final r in _aiResults!) ...[
              _buildAiResultCard(r),
              const SizedBox(height: 8),
            ],

          // Resultats classiques en dessous
          if (_searchResults != null && _searchResults!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Autres resultats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.4))),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    if (_searchResults == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Tape au moins 2 lettres',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Text(
          'Aucun resultat',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final result = _searchResults![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: switch (result) {
            EventResult(:final event) => EventRowCard(event: event),
            MatchResult(:final match) => MatchRowCard(match: match),
            VenueResult() => _VenueRowCard(venue: result),
          },
        );
      },
    );
  }

  // ── Event feed ──

  static const _categoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'expo': 'assets/images/pochette_culture_art.png',
    'vernissage': 'assets/images/pochette_culture_art.png',
    'musee': 'assets/images/pochette_visite.png',
    'football': 'assets/images/pochette_football.png',
    'rugby': 'assets/images/pochette_rugby.png',
    'basketball': 'assets/images/pochette_basketball.png',
    'soiree': 'assets/images/pochette_discotheque.png',
    'club': 'assets/images/pochette_discotheque.png',
    'bar': 'assets/images/pochette_pub.png',
    'restaurant': 'assets/images/pochette_food.png',
    'cinema': 'assets/images/pochette_spectacle.png',
  };

  Widget _buildAiResultCard(Map<String, dynamic> r) {
    final titre = r['titre'] as String? ?? '';
    final date = r['date'] as String? ?? '';
    final horaires = r['horaires'] as String? ?? '';
    final lieu = r['lieu'] as String? ?? '';
    final photo = r['photo'] as String? ?? '';
    final gratuit = r['gratuit'] as bool? ?? false;

    return GestureDetector(
      onTap: () async {
        final id = r['identifiant'] as String? ?? '';
        if (id.isEmpty) return;
        try {
          final event = await ScrapedEventsSupabaseService().fetchEventById(id);
          if (event != null && mounted) {
            EventFullscreenPopup.show(context, event, 'assets/images/pochette_default.jpg');
          }
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (photo.isNotEmpty && photo.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: photo, width: 50, height: 50, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(width: 50, height: 50)),
              )
            else
              Container(width: 50, height: 50, decoration: BoxDecoration(
                color: const Color(0xFF3A3A4E), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event, color: Colors.white24, size: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('$date ${horaires.isNotEmpty ? "- $horaires" : ""} ${lieu.isNotEmpty ? "- $lieu" : ""}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
            if (gratuit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('GRATUIT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }

  static String _resolvePochette(Event e) {
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    for (final entry in _categoryImages.entries) {
      if (cat.contains(entry.key) || type.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/pochette_concert.png';
  }

  static String _resolveMatchPochette(SupabaseMatch m) {
    final sport = m.sport.toLowerCase();
    if (sport.contains('rugby')) return 'assets/images/pochette_rugby.png';
    if (sport.contains('foot')) return 'assets/images/pochette_football.png';
    if (sport.contains('basket')) return 'assets/images/pochette_basketball.png';
    if (sport.contains('hand')) return 'assets/images/pochette_handball.png';
    return 'assets/images/pochette_course.png';
  }

  Widget _buildFeed() {
    // Invalider le feed quand la ville change
    ref.listen(selectedCityProvider, (prev, next) {
      if (prev != next) {
        ref.invalidate(paginatedFeedProvider);
      }
    });

    // Filtre actif → community feed (grille 3 colonnes groupee par jour)
    if (_activeTab != null) {
      // Famille et Food ont des providers dedies (Event > Famille / Event > Food)
      if (_activeSub == 'Famille') {
        final userEvents = ref.watch(familyUserEventsProvider);
        final scrapedAsync = ref.watch(familyScrapedEventsProvider);
        final scraped = scrapedAsync.valueOrNull ?? [];
        return _buildCommunityFeed([...userEvents, ...scraped], Icons.family_restroom, 'famille');
      }
      if (_activeSub == 'Food') {
        final userEvents = ref.watch(foodUserEventsProvider);
        final city = ref.watch(selectedCityProvider);
        final scrapedAsync = ref.watch(_foodScrapedProvider(city));
        final scraped = scrapedAsync.valueOrNull ?? [];
        return _buildCommunityFeed([...userEvents, ...scraped], Icons.restaurant, 'food');
      }

      // Autres filtres : meme feed grid que "Tout" avec pagination infinie
      // _matchesFilter est applique dans _buildFeedGrid
    }

    // "Tout" : feed grid classique (2 colonnes, pagination)
    final feedState = ref.watch(paginatedFeedProvider);

    if (feedState.events.isEmpty && feedState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
    }

    return _buildFeedGrid(
      TodayEventsData(events: feedState.events, matches: feedState.matches),
      isLoadingMore: feedState.isLoading,
      hasMore: feedState.hasMore,
      onLoadMore: () => ref.read(paginatedFeedProvider.notifier).loadNextPage(),
      scrollController: _feedScrollController,
    );
  }

  Widget _buildCommunityFeed(List<Event> events, IconData emptyIcon, String label) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final filtered = events.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return !DateTime(d.year, d.month, d.day).isBefore(today);
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Aucun evenement $label a venir',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final dayGroups = <DateTime, List<_FeedItem>>{};
    // Liste plate pour le swipe dans le popup
    final flatEvents = <Event>[];
    for (final e in filtered) {
      final d = DateTime.tryParse(e.dateDebut)!;
      final dateOnly = DateTime(d.year, d.month, d.day);
      final idx = flatEvents.length;
      flatEvents.add(e);

      final pochette = _resolvePochette(e);
      final hasNet = e.photoPath != null &&
          e.photoPath!.isNotEmpty &&
          e.photoPath!.startsWith('http');

      dayGroups.putIfAbsent(dateOnly, () => []).add(_FeedItem(
        title: e.titre,
        subtitle: e.lieuNom.isNotEmpty ? e.lieuNom : (e.horaires.isNotEmpty ? e.horaires : ''),
        networkImage: hasNet ? e.photoPath : null,
        assetImage: pochette,
        videoUrl: e.videoUrl,
        badge: e.isFree ? 'GRATUIT' : '',
        tag: e.categorie,
        onTap: () => EventFullscreenPopup.showPaged(
          context,
          events: flatEvents,
          initialIndex: idx,
          fallbackAssetBuilder: _resolvePochette,
        ),
        pinSource: AdminPinSource.scrapedEvents,
        pinIdentifiant: e.identifiant,
        pinEventName: e.titre,
        pinDateFin: e.dateFin,
        pinDateDebut: e.dateDebut,
      ));
    }

    final sortedDays = dayGroups.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        for (final day in sortedDays) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day == today
                              ? "Aujourd'hui"
                              : day == tomorrow
                                  ? 'Demain'
                                  : _capitalize(DateFormat('EEEE', 'fr_FR').format(day)),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE d MMMM', 'fr_FR').format(day),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dayGroups[day]!.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _FeedTile(item: dayGroups[day]![index]),
                childCount: dayGroups[day]!.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildFeedGrid(
    TodayEventsData data, {
    bool isLoadingMore = false,
    bool hasMore = false,
    VoidCallback? onLoadMore,
    ScrollController? scrollController,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Group events by day
    final dayGroups = <DateTime, List<_FeedItem>>{};
    // Liste plate pour le swipe dans le popup
    final flatEvents = <Event>[];
    for (final e in data.events) {
      if (!_matchesFilter(e)) continue;
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (dateOnly.isBefore(today)) continue;

      final idx = flatEvents.length;
      flatEvents.add(e);

      final pochette = _resolvePochette(e);
      final hasNet = e.photoPath != null &&
          e.photoPath!.isNotEmpty &&
          e.photoPath!.startsWith('http');

      dayGroups.putIfAbsent(dateOnly, () => []).add(_FeedItem(
        title: e.titre,
        subtitle: e.lieuNom.isNotEmpty ? e.lieuNom : (e.horaires.isNotEmpty ? e.horaires : ''),
        networkImage: hasNet ? e.photoPath : null,
        assetImage: pochette,
        videoUrl: e.videoUrl,
        badge: e.isFree ? 'GRATUIT' : '',
        tag: e.categorie,
        onTap: () => EventFullscreenPopup.showPaged(
          context,
          events: flatEvents,
          initialIndex: idx,
          fallbackAssetBuilder: _resolvePochette,
        ),
        pinSource: AdminPinSource.scrapedEvents,
        pinIdentifiant: e.identifiant,
        pinEventName: e.titre,
        pinDateFin: e.dateFin,
        pinDateDebut: e.dateDebut,
      ));
    }

    // Matchs exclus du feed

    if (dayGroups.isEmpty && !_isLandscape && _activeTab == null) {
      // Meme quand il n'y a pas d'events, afficher la section signalements
      return CustomScrollView(
        slivers: [
          _buildSignalementsSection(),
          const SliverToBoxAdapter(child: BoostedEventsCarousel()),
          const SliverToBoxAdapter(child: BoostedP2Carousel()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun evenement a venir',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (dayGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Aucun evenement a venir',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final sortedDays = dayGroups.keys.toList()..sort();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            onLoadMore != null &&
            notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 300) {
          onLoadMore();
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Discovery + signalements commu + Boosted inseres en haut du feed scroll
          if (!_isLandscape && _activeTab == null) ...[
            // DiscoveryButtons deplace dans Explorer (home_screen)
            // Section : signalements communautaires (style Waze) — EN PREMIER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag,
                      size: 14,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ca bouge pres de toi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0xFF7B2D8E),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _openVideoReport,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Live Notif',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
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
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ReportedEventsMap(height: 280),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            const SliverToBoxAdapter(child: ReportedEventsLegend()),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: ReportedEventsCarousel(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Boosted events (A la une + Au top)
            const SliverToBoxAdapter(child: BoostedEventsCarousel()),
            const SliverToBoxAdapter(child: BoostedP2Carousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
          for (final day in sortedDays) ...[
            SliverToBoxAdapter(
              key: ValueKey('header_$day'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day == today
                                ? "Aujourd'hui"
                                : day == tomorrow
                                    ? 'Demain'
                                    : _capitalize(DateFormat('EEEE', 'fr_FR').format(day)),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE d MMMM', 'fr_FR').format(day),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayGroups[day]!.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              key: ValueKey('grid_$day'),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FeedTile(item: dayGroups[day]![index]),
                  childCount: dayGroups[day]!.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Day header for flat list ──

class _DayHeader {
  final DateTime day;
  final int count;
  final DateTime today;
  final DateTime tomorrow;

  const _DayHeader({
    required this.day,
    required this.count,
    required this.today,
    required this.tomorrow,
  });
}

// ── Feed item model ──

class _FeedItem {
  final String title;
  final String subtitle;
  final String? networkImage;
  final String? assetImage;
  final String? videoUrl;
  final String badge;
  final String tag;
  final VoidCallback onTap;

  // Metadata admin pin (appui-long -> popup "A la une / Au top").
  // Optionnel : si [pinIdentifiant] null, l'appui-long est no-op.
  final AdminPinSource? pinSource;
  final String? pinIdentifiant;
  final String? pinEventName;
  final String? pinDateFin;
  final String? pinDateDebut;

  const _FeedItem({
    required this.title,
    required this.subtitle,
    this.networkImage,
    this.assetImage,
    this.videoUrl,
    required this.badge,
    required this.tag,
    required this.onTap,
    this.pinSource,
    this.pinIdentifiant,
    this.pinEventName,
    this.pinDateFin,
    this.pinDateDebut,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}

// ── Feed tile (Instagram-style) ──

class _FeedTile extends StatelessWidget {
  final _FeedItem item;

  const _FeedTile({super.key, required this.item});

  static bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    return !lower.contains('/embed') &&
        !lower.contains('secret=') &&
        !lower.endsWith('.html') &&
        !lower.endsWith('/');
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = item.pinSource != null && (item.pinIdentifiant?.isNotEmpty ?? false);
    return RepaintBoundary(
      child: hasPin
          ? AdminPinGesture(
              source: item.pinSource!,
              identifiant: item.pinIdentifiant!,
              eventName: item.pinEventName ?? item.title,
              dateFin: item.pinDateFin ?? '',
              dateDebutFallback: item.pinDateDebut,
              child: _buildTap(context),
            )
          : _buildTap(context),
    );
  }

  Widget _buildTap(BuildContext context) {
    return GestureDetector(
        onTap: item.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background : video ou image
            if (item.hasVideo)
              _VideoBackground(videoUrl: item.videoUrl!, tileId: item.title)
            else
              _ImageBackground(item: item),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Video icon indicator
            if (item.hasVideo)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                ),
              ),

            // Badge top-right
            if (item.badge.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E8C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.badge,
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Title + subtitle bottom
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: Colors.white60,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    );
  }
}

/// Image background widget (extracted for clarity).
class _ImageBackground extends StatelessWidget {
  final _FeedItem item;
  const _ImageBackground({required this.item});

  @override
  Widget build(BuildContext context) {
    final validNet = item.networkImage != null && _FeedTile._isValidImageUrl(item.networkImage!);
    if (validNet) {
      return CachedNetworkImage(
        imageUrl: item.networkImage!,
        fit: BoxFit.cover,
        memCacheWidth: 300,
        fadeInDuration: Duration.zero,
        placeholder: (_, __) => _assetFallback(),
        errorWidget: (_, __, ___) => _assetFallback(),
      );
    }
    if (item.assetImage != null) {
      return Image.asset(
        item.assetImage!,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
      );
    }
    return Container(color: Colors.grey.shade900);
  }

  Widget _assetFallback() => item.assetImage != null
      ? Image.asset(item.assetImage!, fit: BoxFit.cover, cacheWidth: 300)
      : Container(color: Colors.grey.shade900);
}

/// Video background with autoplay mute + visibility tracking.
/// One video active at a time (via activeVideoProvider).
class _VideoBackground extends ConsumerStatefulWidget {
  final String videoUrl;
  final String tileId;

  const _VideoBackground({required this.videoUrl, required this.tileId});

  @override
  ConsumerState<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends ConsumerState<_VideoBackground> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _visible = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final fraction = info.visibleFraction;
    if (fraction > 0.5 && !_visible) {
      _visible = true;
      _startPlayback();
    } else if (fraction <= 0.5 && _visible) {
      _visible = false;
      _stopPlayback();
    }
  }

  Future<void> _startPlayback() async {
    // Signal que cette video est active
    ref.read(activeVideoProvider.notifier).state = widget.tileId;

    if (_controller == null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      try {
        await _controller!.initialize();
        _controller!.setLooping(true);
        _controller!.setVolume(0); // Mute par defaut
        if (mounted && _visible) {
          setState(() => _initialized = true);
          _controller!.play();
        }
      } catch (e) {
        debugPrint('[VideoFeed] init error: $e');
      }
    } else if (_initialized) {
      _controller!.play();
    }
  }

  void _stopPlayback() {
    _controller?.pause();
  }

  @override
  Widget build(BuildContext context) {
    // Pause si un autre tile est devenu actif
    ref.listen(activeVideoProvider, (prev, next) {
      if (next != widget.tileId && _controller?.value.isPlaying == true) {
        _controller?.pause();
      }
    });

    return VisibilityDetector(
      key: Key('video_${widget.tileId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _initialized && _controller != null
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          : Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white24, size: 24),
              ),
            ),
    );
  }
}

// ── Venue row card for search results ──

class _VenueRowCard extends StatelessWidget {
  final VenueResult venue;

  const _VenueRowCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVenue(),
      child: Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              _resolveIcon(venue.categorie),
              color: Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (venue.categorie.isNotEmpty)
                    Text(
                      venue.categorie,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _openVenue() {
    // Priorite : site web > lien maps > recherche Google
    final url = (venue.siteWeb != null && venue.siteWeb!.isNotEmpty)
        ? venue.siteWeb!
        : (venue.lienMaps != null && venue.lienMaps!.isNotEmpty)
            ? venue.lienMaps!
            : 'https://www.google.com/search?q=${Uri.encodeComponent(venue.name)}';
    final uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static IconData _resolveIcon(String categorie) {
    final cat = categorie.toLowerCase();
    if (cat.contains('restaurant')) return Icons.restaurant;
    if (cat.contains('cafe') || cat.contains('brunch')) return Icons.coffee;
    if (cat.contains('bar')) return Icons.local_bar;
    if (cat.contains('club') || cat.contains('disco')) return Icons.nightlife;
    if (cat.contains('hotel')) return Icons.hotel;
    if (cat.contains('epicerie')) return Icons.store;
    if (cat.contains('fitness') || cat.contains('sport')) return Icons.fitness_center;
    if (cat.contains('bien-etre') || cat.contains('spa')) return Icons.spa;
    return Icons.place;
  }
}
