import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/weekend_picks_provider.dart';

class WeekendPicksSheet extends ConsumerWidget {
  const WeekendPicksSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeekendPicksSheet(),
    );
  }

  static const _accent = Color(0xFF7B2D8E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picksAsync = ref.watch(weekendPicksProvider);
    final city = ref.watch(selectedCityProvider);

    // Calculer les dates du week-end
    final now = DateTime.now();
    final daysUntilSat = (6 - now.weekday) % 7;
    final saturday = now.add(Duration(days: daysUntilSat == 0 && now.weekday != 6 ? 7 : daysUntilSat));
    final weekendLabel = DateFormat('d MMMM', 'fr_FR').format(saturday);

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
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Ce week-end a $city',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Week-end du $weekendLabel',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Notre selection',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: picksAsync.when(
              data: (picks) => picks.isEmpty
                  ? _buildEmpty(city)
                  : _buildPicks(context, ref, picks),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _accent),
              ),
              error: (_, __) => _buildEmpty(city),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String city) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\uD83C\uDF1F', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Les picks du week-end\narrivent bientot !',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les 3 incontournables\nselectionnes chaque vendredi pour $city.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicks(BuildContext context, WidgetRef ref, List<WeekendPick> picks) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: picks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final pick = picks[i];
        return _PickCard(pick: pick, rank: i + 1);
      },
    );
  }
}

class _PickCard extends StatelessWidget {
  final WeekendPick pick;
  final int rank;

  const _PickCard({required this.pick, required this.rank});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pick.photoUrl.isNotEmpty && pick.photoUrl.startsWith('http');

    return GestureDetector(
      onTap: () => _openEvent(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2A2A3E),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge rank
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    CachedNetworkImage(
                      imageUrl: pick.photoUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF3A3A4E),
                        child: const Icon(Icons.event, color: Colors.white24, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF3A3A4E),
                      child: const Icon(Icons.event, color: Colors.white24, size: 40),
                    ),
                  // Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Rank badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Categorie badge
                  if (pick.categorie.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pick.categorie,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Titre en bas
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      pick.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Resume IA + infos
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resume editorial IA
                  if (pick.resume.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('\u2728 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            pick.resume,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Date + heure + lieu
                  Row(
                    children: [
                      if (pick.date.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(pick.date),
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                      if (pick.horaires.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          pick.horaires,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
                  if (pick.lieu.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pick.lieu,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('EEEE d MMMM', 'fr_FR').format(d);
  }

  Future<void> _openEvent(BuildContext context) async {
    // Charger l'event complet depuis la DB
    try {
      final event = await ScrapedEventsSupabaseService().fetchEventById(pick.identifiant);
      if (event != null && context.mounted) {
        Navigator.pop(context);
        EventFullscreenPopup.show(context, event, 'assets/images/pochette_default.jpg');
      }
    } catch (_) {}
  }
}
