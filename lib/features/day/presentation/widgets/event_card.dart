import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

class EventCard extends ConsumerWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  static final _displayDateFormat = DateFormat('dd/MM/yyyy');

  /// Formate "2026-03-08" → "08/03/2026". Retourne tel quel si parsing echoue.
  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  static const _categoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'expo': 'assets/images/pochette_culture_art.png',
    'vernissage': 'assets/images/pochette_culture_art.png',
    'visites guidees': 'assets/images/pochette_visite.png',
    'animations culturelles': 'assets/images/pochette_animation.png',
    'musee': 'assets/images/pochette_visite.png',
    'football': 'assets/images/pochette_football.png',
    'rugby': 'assets/images/pochette_rugby.png',
    'basketball': 'assets/images/pochette_basketball.png',
    'course': 'assets/images/pochette_course.png',
    'parc': 'assets/images/pochette_parc_attraction.png',
    'cinema': 'assets/images/pochette_spectacle.png',
    'bowling': 'assets/images/pochette_enfamille.png',
    'spectacle enfant': 'assets/images/pochette_enfamille.png',
    'restaurant': 'assets/images/pochette_food.png',
    'cafe': 'assets/images/pochette_food.png',
    'brunch': 'assets/images/pochette_food.png',
    'bar': 'assets/images/pochette_pub.png',
    'club': 'assets/images/pochette_discotheque.png',
    'soiree': 'assets/images/pochette_discotheque.png',
    'concert live': 'assets/images/pochette_concert.png',
  };

  String? _resolveImage() {
    final cat = event.categorie.toLowerCase();
    final type = event.type.toLowerCase();

    // Try exact match on categorie
    if (_categoryImages.containsKey(cat)) return _categoryImages[cat];
    // Try exact match on type
    if (_categoryImages.containsKey(type)) return _categoryImages[type];

    // Try partial match
    for (final entry in _categoryImages.entries) {
      if (cat.contains(entry.key) || type.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback by keyword
    if (cat.contains('musique') || cat.contains('concert')) {
      return 'assets/images/pochette_concert.png';
    }
    if (cat.contains('sport')) return 'assets/images/pochette_course.png';
    if (cat.contains('culture') || cat.contains('art')) {
      return 'assets/images/pochette_culture_art.png';
    }
    if (cat.contains('enfant') || cat.contains('famille')) {
      return 'assets/images/pochette_enfamille.png';
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final likes = ref.watch(likesProvider);
    final isLiked = likes.contains(event.identifiant);
    final pochette = _resolveImage();

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pochette image ──
          if (pochette != null)
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: Image.asset(
                    pochette,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title on image
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    event.titre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Free badge
                if (event.isFree)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E8C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Emoji badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      event.categoryEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),

          // ── No pochette: fallback title row ──
          if (pochette == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.categoryEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E8C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                if (event.dateDebut.isNotEmpty)
                  _buildInfoRow(
                    Icons.calendar_today,
                    event.dateFin.isNotEmpty &&
                            event.dateFin != event.dateDebut
                        ? '${_formatDate(event.dateDebut)} - ${_formatDate(event.dateFin)}'
                        : _formatDate(event.dateDebut),
                    modeTheme.primaryColor,
                  ),

                // Location
                if (event.lieuNom.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    event.lieuNom,
                    modeTheme.primaryColor,
                  ),
                ],

                // Horaires
                if (event.horaires.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.access_time,
                    event.horaires,
                    modeTheme.primaryColor,
                  ),
                ],

                // Tarif
                if (!event.isFree && event.tarifNormal.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.euro,
                    event.tarifNormal,
                    modeTheme.primaryColor,
                  ),
                ],

                const SizedBox(height: 8),

                // Description preview
                if (event.descriptifCourt.isNotEmpty)
                  Text(
                    event.descriptifCourt,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                // Billetterie button
                if (event.reservationUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(event.reservationUrl),
                        icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                        label: const Text('Billetterie'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: modeTheme.primaryColor,
                          side: BorderSide(color: modeTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Like button
                    IconButton(
                      onPressed: () {
                        ref
                            .read(likesProvider.notifier)
                            .toggle(event.identifiant);
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey.shade500,
                        size: 22,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: isLiked
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                    ),

                    const SizedBox(width: 4),

                    // Share button
                    IconButton(
                      onPressed: () => _shareEvent(),
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Partager',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareEvent() {
    final buffer = StringBuffer();
    buffer.writeln(event.titre);
    if (event.dateDebut.isNotEmpty) {
      buffer.writeln('Date: ${event.dateDebut}');
    }
    if (event.lieuNom.isNotEmpty) {
      buffer.writeln('Lieu: ${event.lieuNom}');
    }
    if (event.isFree) {
      buffer.writeln('Gratuit !');
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
