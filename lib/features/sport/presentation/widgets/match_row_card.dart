import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Carte match en ligne : image sport a gauche, infos a droite.
class MatchRowCard extends ConsumerWidget {
  final SupabaseMatch match;

  const MatchRowCard({super.key, required this.match});

  static const _sportImages = <String, String>{
    'football': 'assets/images/pochette_football.png',
    'foot': 'assets/images/pochette_football.png',
    'rugby': 'assets/images/pochette_rugby.png',
    'basket': 'assets/images/pochette_basketball.png',
    'handball': 'assets/images/pochette_handball.png',
    'boxe': 'assets/images/pochette_boxe.png',
    'natation': 'assets/images/pochette_natation.png',
    'course': 'assets/images/pochette_course.png',
    'fitness': 'assets/images/pochette_fitness.png',
  };

  String _resolveImage() {
    // Pochette specifique par equipe
    final equipe = match.equipe1.toLowerCase();
    if (equipe.contains('stade toulousain')) {
      return 'assets/images/pochette_rugby-st.png';
    }
    if (equipe.contains('colomiers') && match.sport.toLowerCase().contains('rugby')) {
      return 'assets/images/pochette_rugby-colomiers.png';
    }
    if (equipe.contains('tmb')) {
      return 'assets/images/pochette_basketball-tmb.png';
    }
    if (equipe.contains('tbc') || equipe.contains('toulouse bc')) {
      return 'assets/images/pochette_basketball-tbc.png';
    }
    if (equipe.contains('fenix')) {
      return 'assets/images/pochette_handball-fenix.png';
    }
    if (equipe.contains('tfc') || equipe.contains('toulouse fc')) {
      return 'assets/images/pochette_football-tfc.png';
    }
    if (match.billetterie.contains('uscnat.fr')) {
      return 'assets/images/pochette_natation-usc.png';
    }

    final sport = match.sport.toLowerCase();
    final comp = match.competition.toLowerCase();
    for (final entry in _sportImages.entries) {
      if (sport.contains(entry.key) || comp.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/sc_autres_sport.png';
  }

  String _sportEmoji() {
    final sport = match.sport.toLowerCase();
    if (sport.contains('foot')) return '\u26BD';
    if (sport.contains('rugby')) return '\uD83C\uDFC9';
    if (sport.contains('basket')) return '\uD83C\uDFC0';
    if (sport.contains('handball') || sport.contains('hand')) return '\uD83E\uDD3E';
    if (sport.contains('boxe')) return '\uD83E\uDD4A';
    if (sport.contains('natation')) return '\uD83C\uDFCA';
    if (sport.contains('course')) return '\uD83C\uDFC3';
    if (sport.contains('fitness')) return '\uD83D\uDCAA';
    return '\uD83C\uDFC5';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final image = _resolveImage();

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 85,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image a gauche ──
            SizedBox(
              width: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Emoji badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _sportEmoji(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  // Badge gratuit
                  if (match.gratuit.toLowerCase() == 'oui')
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'GRATUIT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Competition
                    if (match.competition.isNotEmpty)
                      Text(
                        match.competition,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: modeTheme.primaryColor,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 2),

                    // Equipes
                    Text(
                      '${match.equipe1}  vs  ${match.equipe2}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Date & heure
                    if (match.date.isNotEmpty)
                      _buildInfoRow(
                        Icons.calendar_today,
                        match.heure.isNotEmpty
                            ? '${_formatDate(match.date)} - ${match.heure}'
                            : _formatDate(match.date),
                        modeTheme.primaryColor,
                      ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _openDetail(BuildContext context) {
    final image = _resolveImage();
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: '${match.equipe1}  vs  ${match.equipe2}',
        emoji: _sportEmoji(),
        imageAsset: image,
        infos: [
          if (match.sport.isNotEmpty)
            DetailInfoItem(Icons.sports, match.sport),
          if (match.competition.isNotEmpty)
            DetailInfoItem(Icons.emoji_events_outlined, match.competition),
          if (match.date.isNotEmpty)
            DetailInfoItem(
              Icons.calendar_today,
              match.heure.isNotEmpty
                  ? '${_formatDate(match.date)} - ${match.heure}'
                  : _formatDate(match.date),
            ),
          if (match.lieu.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, match.lieu),
          if (match.ville.isNotEmpty)
            DetailInfoItem(Icons.location_city, match.ville),
          if (match.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, match.description),
          if (match.gratuit.toLowerCase() == 'oui')
            DetailInfoItem(Icons.money_off, 'Gratuit'),
        ],
        primaryAction: match.billetterie.isNotEmpty
            ? DetailAction(
                icon: Icons.confirmation_number_outlined,
                label: 'Billetterie',
                url: match.billetterie,
              )
            : null,
        shareText: _buildShareText(),
      ),
    );
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('${match.equipe1} vs ${match.equipe2}');
    if (match.competition.isNotEmpty) buffer.writeln(match.competition);
    if (match.date.isNotEmpty) buffer.writeln('Date: ${match.date}');
    if (match.lieu.isNotEmpty) buffer.writeln('Lieu: ${match.lieu}');
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return raw;
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
