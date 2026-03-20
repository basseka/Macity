import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
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
import 'package:pulz_app/features/notifications/presentation/mairie_notifications_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/my_publications_sheet.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/animated_ad_banner.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const _accentColor = Color(0xFFE91E8C);

  // Filters
  static const _filters = <String, List<String>>{
    'Concert': ['concert', 'musique'],
    'Spectacles': ['spectacle', 'opera', 'comedie', 'humour', 'stand-up'],
    'Theatre': ['theatre', 'théâtre'],
    'Soiree': ['soiree', 'soirée', 'club', 'dj', 'night'],
    'Famille': ['famille', 'enfant', 'family', 'jeune public'],
    'Food': ['food', 'restaurant', 'gastronomie', 'marche', 'brunch'],
  };
  String? _activeFilter;

  // Search state
  final _searchController = TextEditingController();
  final _searchService = UnifiedSearchService();
  bool _isSearching = false;
  bool _searchLoading = false;
  List<SearchResult>? _searchResults;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = null;
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
      final results = await _searchService.search(query, ville: ville);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
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
          child: Column(
            children: [
              _buildHeader(),
              if (!_isSearching) const AnimatedAdBanner(),
              if (!_isSearching) _buildFilterBar(),
              Expanded(
                child: _isSearching ? _buildSearchResults() : _buildFeed(),
              ),
            ],
          ),
        ),
      ),
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
                      color: Colors.white70,
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
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "Tout" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _activeFilter == null
                      ? _accentColor
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _activeFilter == null
                        ? _accentColor
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Tout',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _activeFilter == null ? FontWeight.w600 : FontWeight.w400,
                    color: _activeFilter == null ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
          ),
          // Category chips
          for (final label in _filters.keys)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _activeFilter = _activeFilter == label ? null : label;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _activeFilter == label
                        ? _accentColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _activeFilter == label
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _activeFilter == label ? FontWeight.w600 : FontWeight.w400,
                      color: _activeFilter == label ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(Event e) {
    if (_activeFilter == null) return true;
    final keywords = _filters[_activeFilter]!;
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    final titre = e.titre.toLowerCase();
    for (final kw in keywords) {
      if (cat.contains(kw) || type.contains(kw) || titre.contains(kw)) return true;
    }
    return false;
  }

  bool _matchMatchesFilter(SupabaseMatch m) {
    if (_activeFilter == null) return true;
    // Matches are sport — only show if no filter is active
    return false;
  }

  // ── Search results ──

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor),
        ),
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
    if (sport.contains('hand')) return 'assets/images/pochette_hand.png';
    return 'assets/images/pochette_course.png';
  }

  Widget _buildFeed() {
    // Special case: Famille & Food use dedicated community events providers
    if (_activeFilter == 'Famille') {
      return _buildCommunityFeed(ref.watch(familyUserEventsProvider), Icons.family_restroom, 'famille');
    }
    if (_activeFilter == 'Food') {
      return _buildCommunityFeed(ref.watch(foodUserEventsProvider), Icons.restaurant, 'food');
    }

    final dataAsync = ref.watch(todayTomorrowEventsProvider);

    return dataAsync.when(
      data: (data) => _buildFeedGrid(data),
      loading: () => const Center(
        child: CircularProgressIndicator(color: _accentColor),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: Colors.white38)),
      ),
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
    for (final e in filtered) {
      final d = DateTime.tryParse(e.dateDebut)!;
      final dateOnly = DateTime(d.year, d.month, d.day);

      final pochette = _resolvePochette(e);
      final hasNet = e.photoPath != null &&
          e.photoPath!.isNotEmpty &&
          e.photoPath!.startsWith('http');

      dayGroups.putIfAbsent(dateOnly, () => []).add(_FeedItem(
        title: e.titre,
        subtitle: e.lieuNom.isNotEmpty ? e.lieuNom : (e.horaires.isNotEmpty ? e.horaires : ''),
        networkImage: hasNet ? e.photoPath : null,
        assetImage: pochette,
        badge: e.isFree ? 'GRATUIT' : '',
        tag: e.categorie,
        onTap: () => EventFullscreenPopup.show(context, e, pochette),
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

  Widget _buildFeedGrid(TodayEventsData data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Group events by day
    final dayGroups = <DateTime, List<_FeedItem>>{};

    for (final e in data.events) {
      if (!_matchesFilter(e)) continue;
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (dateOnly.isBefore(today)) continue;

      final pochette = _resolvePochette(e);
      final hasNet = e.photoPath != null &&
          e.photoPath!.isNotEmpty &&
          e.photoPath!.startsWith('http');

      dayGroups.putIfAbsent(dateOnly, () => []).add(_FeedItem(
        title: e.titre,
        subtitle: e.lieuNom.isNotEmpty ? e.lieuNom : (e.horaires.isNotEmpty ? e.horaires : ''),
        networkImage: hasNet ? e.photoPath : null,
        assetImage: pochette,
        badge: e.isFree ? 'GRATUIT' : '',
        tag: e.categorie,
        onTap: () => EventFullscreenPopup.show(context, e, pochette),
      ));
    }

    // Add matches
    for (final m in data.matches) {
      if (!_matchMatchesFilter(m)) continue;
      final d = DateTime.tryParse(m.date);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (dateOnly.isBefore(today)) continue;

      final pochette = _resolveMatchPochette(m);
      dayGroups.putIfAbsent(dateOnly, () => []).add(_FeedItem(
        title: '${m.equipe1} vs ${m.equipe2}',
        subtitle: '${m.heure} - ${m.lieu}',
        networkImage: m.photoUrl.isNotEmpty ? m.photoUrl : null,
        assetImage: pochette,
        badge: m.sport.toUpperCase(),
        tag: m.sport,
        onTap: () => ItemDetailSheet.show(
          context,
          ItemDetailSheet(
            title: '${m.equipe1} vs ${m.equipe2}',
            imageAsset: pochette,
            infos: [
              if (m.competition.isNotEmpty) DetailInfoItem(Icons.emoji_events, m.competition),
              if (m.lieu.isNotEmpty) DetailInfoItem(Icons.location_on, m.lieu),
              if (m.date.isNotEmpty) DetailInfoItem(Icons.calendar_today, m.date),
              if (m.heure.isNotEmpty) DetailInfoItem(Icons.access_time, m.heure),
            ],
            primaryAction: m.billetterie.isNotEmpty
                ? DetailAction(icon: Icons.confirmation_number, label: 'Billetterie', url: m.billetterie)
                : null,
          ),
        ),
      ));
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

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Feed item model ──

class _FeedItem {
  final String title;
  final String subtitle;
  final String? networkImage;
  final String? assetImage;
  final String badge;
  final String tag;
  final VoidCallback onTap;

  const _FeedItem({
    required this.title,
    required this.subtitle,
    this.networkImage,
    this.assetImage,
    required this.badge,
    required this.tag,
    required this.onTap,
  });
}

// ── Feed tile (Instagram-style) ──

class _FeedTile extends StatelessWidget {
  final _FeedItem item;

  const _FeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (item.networkImage != null)
            CachedNetworkImage(
              imageUrl: item.networkImage!,
              fit: BoxFit.cover,
              placeholder: (_, __) => item.assetImage != null
                  ? Image.asset(item.assetImage!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade900),
              errorWidget: (_, __, ___) => item.assetImage != null
                  ? Image.asset(item.assetImage!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade900),
            )
          else if (item.assetImage != null)
            Image.asset(
              item.assetImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
            )
          else
            Container(color: Colors.grey.shade900),

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
