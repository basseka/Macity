import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Affichage compact en ligne : pochette a gauche, infos a droite.
class EventRowCard extends ConsumerWidget {
  final Event event;

  const EventRowCard({super.key, required this.event});

  static final _displayDateFormat = DateFormat('dd/MM/yyyy');

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  static const _categoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'spectacle': 'assets/images/pochette_spectacle.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'expo': 'assets/images/pochette_culture_art.png',
    'exposition': 'assets/images/pochette_culture_art.png',
    'vernissage': 'assets/images/pochette_culture_art.png',
    'visite': 'assets/images/pochette_visite.png',
    'visite guidee': 'assets/images/pochette_visite.png',
    'visites guidees': 'assets/images/pochette_visite.png',
    'atelier': 'assets/images/pochette_culture_art.png',
    'animation': 'assets/images/pochette_animation.png',
    'animations culturelles': 'assets/images/pochette_animation.png',
    'musee': 'assets/images/pochette_visite.png',
    'concert live': 'assets/images/pochette_concert.png',
  };

  /// Pochettes specifiques par lieu (musees + salles de concert).
  static const _venueImages = <String, String>{
    // ── Musees toulousains ──
    'augustins': 'assets/images/augustin_musee.png',
    'abattoirs': 'assets/images/abbatoirs_musee.png',
    'bemberg': 'assets/images/fondationbemberg_musee.png',
    'paul-dupuy': 'assets/images/pauldupuy_musee.png',
    'paul dupuy': 'assets/images/pauldupuy_musee.png',
    'saint-raymond': 'assets/images/saintraymond_musee.png',
    'vieux toulouse': 'assets/images/vieuxtoulouse_musee.png',
    'histoire de la medecine': 'assets/images/histoiredelamedecine_musee.png',
    'resistance': 'assets/images/museedelaresistance_musee.png',
    'georges labit': 'assets/images/georgeslabit_musee.png',
    'museum de toulouse': 'assets/images/museum_musee.png',
    'jardins du museum': 'assets/images/jardindumuseum_musee.png',
    'cite de l\'espace': 'assets/images/citeespace_museum.png',
    'aeroscopia': 'assets/images/aeroscopia_musee.png',
    'envol des pionniers': 'assets/images/envoldespionniers_musee.png',
    'halle de la machine': 'assets/images/halledelamachine_musee.png',
    'espace patrimoine': 'assets/images/espacepatrimoine_musee.png',
    'chateau d\'eau': 'assets/images/chateaudeau_musee.png',
    // ── Salles de concert ──
    'zenith': 'assets/images/salle_zenith.png',
    'metronum': 'assets/images/pochette_metronum.png',
    'bikini': 'assets/images/salle_bikini.png',
    'halle aux grains': 'assets/images/salle_halleauxgrains.png',
    'saint-pierre-des-cuisines': 'assets/images/pochette_saintpierre.png',
    'nougaro': 'assets/images/salle_nougaro.png',
    'taquin': 'assets/images/salle_taquin.png',
    'rex': 'assets/images/pochette_rex.png',
    'interference': 'assets/images/salle_interference.png',
    'auditorium': 'assets/images/salle_auditorium.png',
    'chapelle du chu': 'assets/images/salle_chapelle.png',
    'hotel-dieu': 'assets/images/salle_chapelle.png',
    'palais consulaire': 'assets/images/salle_palaisconsulaire.png',
    'chapelle des carmelites': 'assets/images/salle_chapelle.png',
    // ── Salles de spectacle ──
    'casino barriere': 'assets/images/casino_barriere.png',
    'hall 8': 'assets/images/hall8.png',
    'espace job': 'assets/images/espacejob.png',
    'bascala': 'assets/images/bascala.png',
  };

  String _resolveImage() {
    // 1. Pochette specifique au lieu (musees)
    final lieu = event.lieuNom.toLowerCase();
    for (final entry in _venueImages.entries) {
      if (lieu.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Pochette par categorie / type
    final cat = event.categorie.toLowerCase();
    final type = event.type.toLowerCase();

    if (_categoryImages.containsKey(cat)) return _categoryImages[cat]!;
    if (_categoryImages.containsKey(type)) return _categoryImages[type]!;

    for (final entry in _categoryImages.entries) {
      if (cat.contains(entry.key) || type.contains(entry.key)) {
        return entry.value;
      }
    }

    if (cat.contains('musique') || cat.contains('concert')) {
      return 'assets/images/pochette_concert.png';
    }

    return 'assets/images/pochette_concert.png';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final likes = ref.watch(likesProvider);
    final isLiked = likes.contains(event.identifiant);
    final pochette = _resolveImage();

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 125,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pochette a gauche ──
            SizedBox(
              width: 95,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPochette(pochette),
                  // Gradient overlay
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
                  // Badge gratuit
                  if (event.isFree)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'GRATUIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
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
                        event.categoryEmoji,
                        style: const TextStyle(fontSize: 14),
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
                    // Titre
                    Text(
                      event.titre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

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

                    // Lieu
                    if (event.lieuNom.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        event.lieuNom,
                        modeTheme.primaryColor,
                      ),
                    ],

                    const Spacer(),

                    // Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Billetterie
                        if (event.reservationUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () => _openUrl(event.reservationUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: modeTheme.primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 11,
                                    color: modeTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Billetterie',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: modeTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Like
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(likesProvider.notifier)
                                .toggle(event.identifiant);
                          },
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey.shade400,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Share
                        GestureDetector(
                          onTap: () => _shareEvent(),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _defaultPochette = 'assets/images/pochette_concert.png';

  /// Construit la pochette : URL réseau > fichier local > asset par défaut.
  Widget _buildPochette(String fallbackAsset) {
    final photo = event.photoPath;
    if (photo == null || photo.isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      );
    }

    // URL réseau (Supabase Storage ou autre)
    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultPochette, fit: BoxFit.cover),
        ),
      );
    }

    // Fichier local
    return Image.file(
      File(photo),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      ),
    );
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
              fontSize: 12,
              color: Colors.grey.shade600,
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
