import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/discovery_providers.dart';

class RightNowSheet extends ConsumerStatefulWidget {
  const RightNowSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RightNowSheet(),
    );
  }

  @override
  ConsumerState<RightNowSheet> createState() => _RightNowSheetState();
}

class _RightNowSheetState extends ConsumerState<RightNowSheet> {
  static const _accent = Color(0xFFE91E8C);

  /// Filtre horaire : null = tout, sinon nombre d'heures max
  int? _hoursFilter;

  /// Parse "20h30" → DateTime d'aujourd'hui a 20:30
  static DateTime? _parseHoraire(String horaires) {
    final m = RegExp(r'(\d{1,2})h(\d{0,2})').firstMatch(horaires);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, min);
  }

  /// Calcule le label "dans Xh", "dans Xmin", "en cours"
  static String _timeLabel(String horaires) {
    final eventTime = _parseHoraire(horaires);
    if (eventTime == null) return '';
    final now = DateTime.now();
    final diff = eventTime.difference(now);
    if (diff.isNegative && diff.inHours > -3) return 'En cours';
    if (diff.isNegative) return '';
    if (diff.inMinutes < 60) return 'Dans ${diff.inMinutes}min';
    if (diff.inHours < 2) return 'Dans 1h${diff.inMinutes % 60 > 0 ? '${(diff.inMinutes % 60).toString().padLeft(2, "0")}' : ''}';
    return 'Dans ${diff.inHours}h';
  }

  /// Filtre un event par le filtre horaire selectionne
  bool _matchesFilter(dynamic event) {
    if (_hoursFilter == null) return true;
    final horaires = event.horaires as String? ?? '';
    if (horaires.isEmpty) return false;
    final eventTime = _parseHoraire(horaires);
    if (eventTime == null) return false;
    final now = DateTime.now();
    final diff = eventTime.difference(now);
    // "En cours" (commence il y a moins de 2h) ou dans les X prochaines heures
    return diff.inHours >= -2 && diff.inHours < _hoursFilter!;
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(rightNowProvider);
    final city = ref.watch(selectedCityProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Ce matin'
        : hour < 18
            ? "Cet apres-midi"
            : 'Ce soir';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\uD83D\uDD25 $greeting a $city',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            DateFormat('EEEE d MMMM - HH:mm', 'fr_FR').format(DateTime.now()),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          // Filtres horaires
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _timeChip(null, 'Tout'),
                _timeChip(1, 'Dans 1h'),
                _timeChip(2, 'Dans 2h'),
                _timeChip(4, 'Dans 4h'),
                _timeChip(8, 'Ce soir'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: dataAsync.when(
              data: (data) => _buildContent(context, data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent),
              ),
              error: (e, _) => Center(
                child: Text('Erreur: $e', style: const TextStyle(color: Colors.white38)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip(int? hours, String label) {
    final selected = _hoursFilter == hours;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _hoursFilter = hours),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RightNowData data) {
    // Filtrer les events par granularite horaire
    final filteredEvents = _hoursFilter == null
        ? data.todayEvents
        : data.todayEvents.where(_matchesFilter).toList();

    // Trier par proximite horaire (les plus proches en premier)
    final sortedEvents = List.of(filteredEvents);
    final now = DateTime.now();
    sortedEvents.sort((a, b) {
      final aTime = _parseHoraire(a.horaires ?? '');
      final bTime = _parseHoraire(b.horaires ?? '');
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.difference(now).inMinutes.abs().compareTo(bTime.difference(now).inMinutes.abs());
    });

    if (sortedEvents.isEmpty && data.todayMatches.isEmpty && data.hotVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\uD83C\uDF19', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _hoursFilter != null
                  ? 'Aucun evenement dans les ${_hoursFilter}h'
                  : 'Rien de special en ce moment',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Events du jour (filtres)
        if (sortedEvents.isNotEmpty) ...[
          _sectionHeader('\uD83C\uDFB6 Evenements', '${sortedEvents.length}'),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sortedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _EventCard(event: sortedEvents[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Matchs du jour
        if (data.todayMatches.isNotEmpty) ...[
          _sectionHeader('\u26BD Matchs', '${data.todayMatches.length}'),
          const SizedBox(height: 8),
          for (final m in data.todayMatches)
            _MatchTile(match: m),
          const SizedBox(height: 20),
        ],

        // Lieux animes
        if (data.hotVenues.isNotEmpty) ...[
          _sectionHeader('\uD83D\uDD25 Lieux animes', '${data.hotVenues.length}'),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.hotVenues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final v = data.hotVenues[i];
                return _VenueChip(
                  name: v.nom,
                  category: v.categorie,
                  count: v.displayCount,
                  photo: v.photo,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _accent),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final dynamic event;
  const _EventCard({required this.event});

  String get _timeLabel => _RightNowSheetState._timeLabel(event.horaires ?? '');
  bool get _isOngoing => _timeLabel == 'En cours';

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photoPath != null &&
        event.photoPath!.isNotEmpty &&
        event.photoPath!.startsWith('http') &&
        !event.photoPath!.contains('/embed');

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        EventFullscreenPopup.show(context, event, 'assets/images/pochette_concert.png');
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF2A2A3E),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: event.photoPath!,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A3E)),
              )
            else
              Container(color: const Color(0xFF2A2A3E)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // Badge "Dans Xh" en haut a gauche
            if (_timeLabel.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isOngoing
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE91E8C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _timeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (event.horaires.isNotEmpty)
                    Text(
                      event.horaires,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
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

class _MatchTile extends StatelessWidget {
  final dynamic match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('\u26BD', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.equipe1} vs ${match.equipe2}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${match.heure} - ${match.lieu}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.sport.toString().toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE91E8C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueChip extends StatelessWidget {
  final String name;
  final String category;
  final int count;
  final String photo;

  const _VenueChip({
    required this.name,
    required this.category,
    required this.count,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Color(0xFFE91E8C)),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE91E8C),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
