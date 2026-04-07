import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

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
    if (sport.contains('hand')) return 'assets/images/pochette_handball.png';
    return 'assets/images/pochette_course.png';
  }

  static final _displayDate = DateFormat('dd/MM', 'fr_FR');
  static final _fullDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(todayTomorrowEventsProvider);
    final userEvents = ref.watch(userEventsProvider);
    final city = ref.watch(selectedCityProvider);

    final userIds = userEvents.map((ue) => ue.id).toSet();
    final cityUserEvents = userEvents
        .where((ue) => ue.ville.toLowerCase() == city.toLowerCase())
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 5),
        body: dataAsync.when(
          data: (data) {
            final scraped = data.events
                .where((e) => !userIds.contains(e.identifiant))
                .toList();

            return _FeedBody(
              scrapedEvents: scraped,
              matches: data.matches,
              userEvents: cityUserEvents,
              resolvePochette: _resolvePochette,
              resolveMatchPochette: _resolveMatchPochette,
              displayDate: _displayDate,
              fullDate: _fullDate,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
          ),
          error: (e, _) => Center(
            child: Text('Erreur: $e',
                style: const TextStyle(color: Colors.white38)),
          ),
        ),
      ),
    );
  }
}

class _FeedBody extends StatefulWidget {
  final List<Event> scrapedEvents;
  final List<SupabaseMatch> matches;
  final List userEvents;
  final String Function(Event) resolvePochette;
  final String Function(SupabaseMatch) resolveMatchPochette;
  final DateFormat displayDate;
  final DateFormat fullDate;

  const _FeedBody({
    required this.scrapedEvents,
    required this.matches,
    required this.userEvents,
    required this.resolvePochette,
    required this.resolveMatchPochette,
    required this.displayDate,
    required this.fullDate,
  });

  @override
  State<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<_FeedBody> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrapedCount = widget.scrapedEvents.length + widget.matches.length;
    final userCount = widget.userEvents.length;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tous les events dans ta poche',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(3),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: const Color(0xFF1A1A2E),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelPadding: EdgeInsets.zero,
              labelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14),
                      const SizedBox(width: 4),
                      const Flexible(child: Text('Tendances', overflow: TextOverflow.ellipsis)),
                      if (scrapedCount > 0) ...[
                        const SizedBox(width: 4),
                        _CountBadge(count: scrapedCount, color: const Color(0xFFE91E8C)),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 14),
                      const SizedBox(width: 4),
                      const Flexible(child: Text('Communaute', overflow: TextOverflow.ellipsis)),
                      if (userCount > 0) ...[
                        const SizedBox(width: 4),
                        _CountBadge(count: userCount, color: const Color(0xFF7C4DFF)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ScrapedGrid(
                  events: widget.scrapedEvents,
                  matches: widget.matches,
                  resolvePochette: widget.resolvePochette,
                  resolveMatchPochette: widget.resolveMatchPochette,
                  displayDate: widget.displayDate,
                  fullDate: widget.fullDate,
                ),
                _UserGrid(
                  userEvents: widget.userEvents,
                  displayDate: widget.displayDate,
                  fullDate: widget.fullDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge compteur ──
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Tab 1 : Tendances
// ══════════════════════════════════════════════
class _ScrapedGrid extends StatelessWidget {
  final List<Event> events;
  final List<SupabaseMatch> matches;
  final String Function(Event) resolvePochette;
  final String Function(SupabaseMatch) resolveMatchPochette;
  final DateFormat displayDate;
  final DateFormat fullDate;

  const _ScrapedGrid({
    required this.events,
    required this.matches,
    required this.resolvePochette,
    required this.resolveMatchPochette,
    required this.displayDate,
    required this.fullDate,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[];

    for (final e in events) {
      final hasNet = e.photoPath != null &&
          e.photoPath!.isNotEmpty &&
          e.photoPath!.startsWith('http');
      final pochette = resolvePochette(e);
      final parsed = DateTime.tryParse(e.dateDebut);
      final dateShort = parsed != null ? displayDate.format(parsed) : '';
      final dateFull = parsed != null ? fullDate.format(parsed) : e.dateDebut;

      tiles.add(_TileData(
        title: e.titre,
        subtitle: dateShort,
        networkImage: hasNet ? e.photoPath : null,
        assetImage: pochette,
        badge: e.isFree ? 'GRATUIT' : '',
        badgeColor: const Color(0xFF00C853),
        lieu: e.lieuNom,
        dateFormatted: dateFull,
        horaires: e.horaires,
        lien: e.reservationUrl,
        accentColor: _TileData.resolveAccent(e),
        vibeIcon: _TileData.resolveVibe(e)?.$1,
        vibeColors: _TileData.resolveVibe(e)?.$2,
        dateKey: parsed != null ? DateTime(parsed.year, parsed.month, parsed.day) : null,
        eventId: e.identifiant,
      ));
    }

    for (final m in matches) {
      final pochette = resolveMatchPochette(m);
      final parsed = DateTime.tryParse(m.date);
      final dateShort = parsed != null ? displayDate.format(parsed) : '';
      final dateFull = parsed != null ? fullDate.format(parsed) : m.date;

      tiles.add(_TileData(
        title: '${m.equipe1} vs ${m.equipe2}',
        subtitle: '${m.heure} - $dateShort',
        networkImage: m.photoUrl.isNotEmpty ? m.photoUrl : null,
        assetImage: pochette,
        badge: m.sport.toUpperCase(),
        badgeColor: const Color(0xFFFF6D00),
        lieu: m.lieu,
        dateFormatted: dateFull,
        horaires: m.heure,
        lien: m.billetterie,
        accentColor: _TileData.matchAccent(m),
        dateKey: parsed != null ? DateTime(parsed.year, parsed.month, parsed.day) : null,
        eventId: 'match_${m.id}',
      ));
    }

    if (tiles.isEmpty) {
      return _EmptyState(icon: Icons.auto_awesome, message: 'Aucun evenement tendance');
    }

    // Trier par date
    tiles.sort((a, b) {
      final da = a.dateKey ?? DateTime(2099);
      final db = b.dateKey ?? DateTime(2099);
      return da.compareTo(db);
    });

    // Grouper par jour
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <DateTime, List<_TileData>>{};
    for (final t in tiles) {
      final key = t.dateKey ?? today;
      (groups[key] ??= []).add(t);
    }

    final sortedDays = groups.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        for (final day in sortedDays) ...[
          SliverToBoxAdapter(
            child: _DateLabel(day: day, today: today),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _FeedTile(data: groups[day]![index]),
                childCount: groups[day]!.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

// ── Label date subtil ──
class _DateLabel extends StatelessWidget {
  final DateTime day;
  final DateTime today;

  const _DateLabel({required this.day, required this.today});

  @override
  Widget build(BuildContext context) {
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    String label;
    if (day == today) {
      label = "Aujourd'hui";
    } else if (day == tomorrow) {
      label = 'Demain';
    } else if (day == dayAfter) {
      label = 'Apres-demain';
    } else {
      final wd = DateFormat('EEEE', 'fr_FR').format(day);
      label = '${wd[0].toUpperCase()}${wd.substring(1)} ${day.day}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day == today
                  ? const Color(0xFFE91E8C)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: day == today
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.3),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Tab 2 : Communaute
// ══════════════════════════════════════════════
class _UserGrid extends StatelessWidget {
  final List userEvents;
  final DateFormat displayDate;
  final DateFormat fullDate;

  const _UserGrid({
    required this.userEvents,
    required this.displayDate,
    required this.fullDate,
  });

  @override
  Widget build(BuildContext context) {
    if (userEvents.isEmpty) {
      return _EmptyState(icon: Icons.people_outline, message: 'Aucun evenement communautaire');
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: userEvents.length,
      itemBuilder: (context, index) {
        final ue = userEvents[index];
        final hasPhoto = ue.resolvedPhoto != null &&
            ue.resolvedPhoto!.isNotEmpty &&
            ue.resolvedPhoto!.startsWith('http');
        final parsed = DateTime.tryParse(ue.date);
        final dateShort = parsed != null ? displayDate.format(parsed) : '';
        final dateFull = parsed != null ? fullDate.format(parsed) : ue.date;

        return _FeedTile(
          data: _TileData(
            title: ue.titre,
            subtitle: '$dateShort - ${ue.heure}',
            networkImage: hasPhoto ? ue.resolvedPhoto : null,
            assetImage: 'assets/images/pochette_concert.png',
            badge: 'COMMUNAUTE',
            badgeColor: const Color(0xFF7C4DFF),
            lieu: ue.lieuNom,
            dateFormatted: dateFull,
            horaires: ue.heure,
            lien: ue.lienBilletterie,
            eventId: ue.id,
          ),
          showUserBorder: true,
        );
      },
    );
  }
}

// ── Etat vide ──
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}

// ── Data model ──
class _TileData {
  final String title;
  final String subtitle;
  final String? networkImage;
  final String? assetImage;
  final String badge;
  final Color badgeColor;
  final String lieu;
  final String dateFormatted;
  final String horaires;
  final String lien;
  final Color accentColor;
  final IconData? vibeIcon;
  final List<Color>? vibeColors;
  final DateTime? dateKey;
  final String eventId;

  const _TileData({
    required this.title,
    required this.subtitle,
    this.networkImage,
    this.assetImage,
    required this.badge,
    required this.badgeColor,
    required this.lieu,
    required this.dateFormatted,
    required this.horaires,
    required this.lien,
    this.accentColor = Colors.transparent,
    this.vibeIcon,
    this.vibeColors,
    this.dateKey,
    this.eventId = '',
  });

  /// Couleur subtile selon la categorie/type de l'event.
  static Color resolveAccent(Event e) {
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    final all = '$cat $type';
    if (all.contains('concert') || all.contains('festival') || all.contains('musique')) {
      return const Color(0xFFE91E8C); // rose — musique
    }
    if (all.contains('theatre') || all.contains('opera') || all.contains('spectacle')) {
      return const Color(0xFFFF6D00); // orange — spectacle
    }
    if (all.contains('expo') || all.contains('musee') || all.contains('vernissage')) {
      return const Color(0xFF667EEA); // bleu — culture/art
    }
    if (all.contains('soiree') || all.contains('club') || all.contains('bar')) {
      return const Color(0xFF7C4DFF); // violet — night
    }
    if (all.contains('cinema')) {
      return const Color(0xFFFFD700); // gold — cinema
    }
    return const Color(0xFF00C9FF); // cyan — default
  }

  /// Icone fete pour soirees / DJ / concerts. Retourne (icon, gradientColors).
  static (IconData, List<Color>)? resolveVibe(Event e) {
    final all = '${e.categorie} ${e.type} ${e.titre}'.toLowerCase();
    if (all.contains('dj') || all.contains('d.j') || all.contains('mix')) {
      return (Icons.headphones, const [Color(0xFF7C4DFF), Color(0xFF5C1FCC)]);
    }
    if (all.contains('soiree') || all.contains('club') || all.contains('nuit')) {
      return (Icons.local_bar, const [Color(0xFFE53935), Color(0xFFB71C1C)]);
    }
    if (all.contains('concert') || all.contains('live') || all.contains('festival')) {
      return (Icons.mic, const [Color(0xFFFFD700), Color(0xFFDAA520)]);
    }
    return null;
  }

  static Color matchAccent(SupabaseMatch m) {
    final sport = m.sport.toLowerCase();
    if (sport.contains('rugby')) return const Color(0xFFFF6D00);
    if (sport.contains('foot')) return const Color(0xFF00C853);
    if (sport.contains('basket')) return const Color(0xFFE91E8C);
    if (sport.contains('hand')) return const Color(0xFF667EEA);
    return const Color(0xFF00C9FF);
  }
}

// ── Tile ──
class _FeedTile extends StatelessWidget {
  final _TileData data;
  final bool showUserBorder;

  const _FeedTile({required this.data, this.showUserBorder = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _EventQuickSheet.show(context, data),
      child: Container(
        decoration: showUserBorder
            ? BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        clipBehavior: showUserBorder ? Clip.antiAlias : Clip.none,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (data.networkImage != null)
              CachedNetworkImage(
                imageUrl: data.networkImage!,
                fit: BoxFit.cover,
                placeholder: (_, __) => data.assetImage != null
                    ? Image.asset(data.assetImage!, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF1A1A2E)),
                errorWidget: (_, __, ___) => data.assetImage != null
                    ? Image.asset(data.assetImage!, fit: BoxFit.cover, cacheWidth: 300)
                    : Container(color: const Color(0xFF1A1A2E)),
              )
            else if (data.assetImage != null)
              Image.asset(
                data.assetImage!,
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
              )
            else
              Container(color: const Color(0xFF1A1A2E)),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),

            if (data.badge.isNotEmpty)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: data.badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.badge,
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

            // Vibe icon (soiree/dj/concert)
            if (data.vibeIcon != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: data.vibeColors ?? const [Color(0xFFFFD700), Color(0xFFDAA520)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(data.vibeIcon!, size: 10, color: Colors.white),
                ),
              ),

            // Accent line
            if (data.accentColor != Colors.transparent)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data.accentColor.withValues(alpha: 0.9),
                        data.accentColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned(
              left: 5,
              right: 5,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: GoogleFonts.inter(fontSize: 8, color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Popup : Où · Quand · Liens — minimaliste
// ══════════════════════════════════════════════════════
class _EventQuickSheet extends ConsumerStatefulWidget {
  final _TileData data;

  const _EventQuickSheet({required this.data});

  static void show(BuildContext context, _TileData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EventQuickSheet(data: data),
    );
  }

  @override
  ConsumerState<_EventQuickSheet> createState() => _EventQuickSheetState();
}

class _EventQuickSheetState extends ConsumerState<_EventQuickSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade1;
  late final Animation<double> _fade2;
  late final Animation<double> _fade3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _fade2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
    );
    _fade3 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasLieu = d.lieu.isNotEmpty;
    final hasDate = d.dateFormatted.isNotEmpty || d.horaires.isNotEmpty;
    final hasLien = d.lien.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Titre
              Text(
                d.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // View + Favori
              Builder(builder: (_) {
                final isLiked = d.eventId.isNotEmpty &&
                    ref.watch(likesProvider).contains(d.eventId);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // View
                    GestureDetector(
                      onTap: () => _showFullImage(context, d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded, size: 14, color: const Color(0xFFFFD700)),
                            const SizedBox(width: 4),
                            Text(
                              'View',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (d.eventId.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      // Favori
                      GestureDetector(
                        onTap: () => ref.read(likesProvider.notifier).toggle(
                          d.eventId,
                          meta: LikeMetadata(
                            title: d.title,
                            imageUrl: d.networkImage,
                            assetImage: d.assetImage,
                            category: d.badge.isNotEmpty ? d.badge : null,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLiked
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: isLiked ? Colors.red : Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLiked ? 'Aime' : 'Aimer',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isLiked ? Colors.red : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 14),

              // 3 lignes
              _buildRow(
                animation: _fade1,
                icon: Icons.location_on_outlined,
                color: const Color(0xFF667EEA),
                value: hasLieu ? d.lieu : '—',
                dimmed: !hasLieu,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),

              _buildRow(
                animation: _fade2,
                icon: Icons.access_time_rounded,
                color: const Color(0xFFE91E8C),
                value: _buildQuandText(),
                dimmed: !hasDate,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),

              _buildRow(
                animation: _fade3,
                icon: Icons.open_in_new_rounded,
                color: const Color(0xFF00C9FF),
                value: hasLien ? 'Billetterie' : '—',
                dimmed: !hasLien,
                onTap: hasLien ? () => _openUrl(d.lien) : null,
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  String _buildQuandText() {
    final d = widget.data;
    final parts = <String>[];
    if (d.dateFormatted.isNotEmpty) parts.add(d.dateFormatted);
    if (d.horaires.isNotEmpty) parts.add(d.horaires);
    return parts.isNotEmpty ? parts.join('  ·  ') : '—';
  }

  Widget _buildRow({
    required Animation<double> animation,
    required IconData icon,
    required Color color,
    required String value,
    required bool dimmed,
    VoidCallback? onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: dimmed ? Colors.white24 : color,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: dimmed ? Colors.white24 : Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, _TileData d) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: _FullImageView(data: d),
          );
        },
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ── Plein ecran affiche ──
class _FullImageView extends StatelessWidget {
  final _TileData data;
  const _FullImageView({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Image centree
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: data.networkImage != null
                        ? CachedNetworkImage(
                            imageUrl: data.networkImage!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => data.assetImage != null
                                ? Image.asset(data.assetImage!, fit: BoxFit.contain)
                                : const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => data.assetImage != null
                                ? Image.asset(data.assetImage!, fit: BoxFit.contain, cacheWidth: 300)
                                : const SizedBox.shrink(),
                          )
                        : data.assetImage != null
                            ? Image.asset(data.assetImage!, fit: BoxFit.contain)
                            : const SizedBox.shrink(),
                  ),
                ),
              ),

              // Bouton fermer
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Titre en bas
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Text(
                  data.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
