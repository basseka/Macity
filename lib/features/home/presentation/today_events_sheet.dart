import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Represente un item generique dans la grille (event ou match).
class _GridItem {
  final String title;
  final String subtitle;
  final String? networkImage;
  final String? assetImage;
  final String badge;
  final VoidCallback onTap;

  const _GridItem({
    required this.title,
    required this.subtitle,
    this.networkImage,
    this.assetImage,
    required this.badge,
    required this.onTap,
  });
}

class TodayEventsSheet extends ConsumerWidget {
  const TodayEventsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TodayEventsSheet(),
    );
  }

  // ── pochette par categorie ──
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

  static final _displayDate = DateFormat('dd/MM', 'fr_FR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(todayTomorrowEventsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFFE91E8C), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Cette semaine',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: Colors.white10),
              // Content
              Expanded(
                child: dataAsync.when(
                  data: (data) =>
                      _buildGrid(context, data, scrollController),
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFE91E8C)),
                  ),
                  error: (e, _) => Center(
                    child: Text('Erreur: $e',
                        style: const TextStyle(color: Colors.white38)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(
      BuildContext context, TodayEventsData data, ScrollController controller) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Grouper par jour sur 7 jours
    final dayGroups = <DateTime, List<_GridItem>>{};
    for (var i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      final items = <_GridItem>[];

      for (final m in data.matches) {
        final d = DateTime.tryParse(m.date);
        if (d == null || DateTime(d.year, d.month, d.day) != day) continue;
        items.add(_matchToGridItem(context, m));
      }
      for (final e in data.events) {
        final d = DateTime.tryParse(e.dateDebut);
        if (d == null || DateTime(d.year, d.month, d.day) != day) continue;
        items.add(_eventToGridItem(context, e));
      }

      if (items.isNotEmpty) {
        dayGroups[day] = items;
      }
    }

    if (dayGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy,
                size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Aucun evenement cette semaine',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final tomorrow = today.add(const Duration(days: 1));

    return CustomScrollView(
      controller: controller,
      slivers: [
        for (final entry in dayGroups.entries) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: entry.key == today
                  ? "Aujourd'hui"
                  : entry.key == tomorrow
                      ? 'Demain'
                      : DateFormat('EEEE', 'fr_FR').format(entry.key).substring(0, 1).toUpperCase() +
                          DateFormat('EEEE', 'fr_FR').format(entry.key).substring(1),
              subtitle: DateFormat('EEEE d MMMM', 'fr_FR').format(entry.key),
              count: entry.value.length,
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
                (context, index) => _GridTile(item: entry.value[index]),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  _GridItem _eventToGridItem(BuildContext context, Event e) {
    final hasNet = e.photoPath != null &&
        e.photoPath!.isNotEmpty &&
        e.photoPath!.startsWith('http');
    final pochette = _resolvePochette(e);
    final parsed = DateTime.tryParse(e.dateDebut);
    final dateLabel = parsed != null ? _displayDate.format(parsed) : '';

    return _GridItem(
      title: e.titre,
      subtitle: dateLabel,
      networkImage: hasNet ? e.photoPath : null,
      assetImage: pochette,
      badge: e.isFree ? 'GRATUIT' : '',
      onTap: () => EventFullscreenPopup.show(context, e, pochette),
    );
  }

  _GridItem _matchToGridItem(BuildContext context, SupabaseMatch m) {
    final pochette = _resolveMatchPochette(m);
    final parsed = DateTime.tryParse(m.date);
    final dateLabel = parsed != null ? _displayDate.format(parsed) : '';

    return _GridItem(
      title: '${m.equipe1} vs ${m.equipe2}',
      subtitle: '${m.heure} - $dateLabel',
      networkImage: m.photoUrl.isNotEmpty ? m.photoUrl : null,
      assetImage: pochette,
      badge: m.sport.toUpperCase(),
      onTap: () => ItemDetailSheet.show(
        context,
        ItemDetailSheet(
          title: '${m.equipe1} vs ${m.equipe2}',
          imageAsset: pochette,
          infos: [
            if (m.competition.isNotEmpty)
              DetailInfoItem(Icons.emoji_events, m.competition),
            if (m.lieu.isNotEmpty)
              DetailInfoItem(Icons.location_on, m.lieu),
            if (m.date.isNotEmpty)
              DetailInfoItem(Icons.calendar_today, m.date),
            if (m.heure.isNotEmpty)
              DetailInfoItem(Icons.access_time, m.heure),
            if (m.score.isNotEmpty)
              DetailInfoItem(Icons.scoreboard, m.score),
          ],
          primaryAction: m.billetterie.isNotEmpty
              ? DetailAction(icon: Icons.confirmation_number, label: 'Billetterie', url: m.billetterie)
              : null,
        ),
      ),
    );
  }
}

// ── Grid tile (style Instagram) ──
class _GridTile extends StatelessWidget {
  final _GridItem item;

  const _GridTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
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
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade900),
            )
          else
            Container(color: Colors.grey.shade900),

          // Gradient bas
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

          // Badge en haut a droite
          if (item.badge.isNotEmpty)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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

          // Titre + sous-titre en bas
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

// ── Section header ──
class _SectionHeader extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;

  const _SectionHeader({
    required this.label,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
              color: const Color(0xFFE91E8C).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE91E8C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
