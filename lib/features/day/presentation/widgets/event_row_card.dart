import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Carte événement : pochette carrée à gauche, infos à droite.
class EventRowCard extends ConsumerWidget {
  final Event event;

  const EventRowCard({super.key, required this.event});

  static final _shortDateFormat = DateFormat('dd/MM');

  static String _formatDateShort(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _shortDateFormat.format(parsed);
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
    'augustins': 'assets/images/augustin_musee.jpg',
    'abattoirs': 'assets/images/abbatoirs_musee.jpg',
    'bemberg': 'assets/images/fondationbemberg_musee.jpg',
    'paul-dupuy': 'assets/images/pauldupuy_musee.jpg',
    'paul dupuy': 'assets/images/pauldupuy_musee.jpg',
    'saint-raymond': 'assets/images/saintraymond_musee.jpg',
    'vieux toulouse': 'assets/images/vieuxtoulouse_musee.jpg',
    'histoire de la medecine': 'assets/images/histoiredelamedecine_musee.jpg',
    'resistance': 'assets/images/museedelaresistance_musee.jpg',
    'georges labit': 'assets/images/georgeslabit_musee.jpg',
    'museum de toulouse': 'assets/images/museum_musee.jpg',
    'jardins du museum': 'assets/images/jardindumuseum_musee.jpg',
    'cite de l\'espace': 'assets/images/citeespace_museum.jpg',
    'aeroscopia': 'assets/images/aeroscopia_musee.jpg',
    'envol des pionniers': 'assets/images/envoldespionniers_musee.jpg',
    'halle de la machine': 'assets/images/halledelamachine_musee.jpg',
    'espace patrimoine': 'assets/images/espacepatrimoine_musee.jpg',
    'chateau d\'eau': 'assets/images/chateaudeau_musee.jpg',
    // ── Salles de concert ──
    'zenith': 'assets/images/salle_zenith.jpg',
    'metronum': 'assets/images/pochette_metronum.jpg',
    'bikini': 'assets/images/salle_bikini.png',
    'halle aux grains': 'assets/images/salle_halleauxgrains.jpg',
    'saint-pierre-des-cuisines': 'assets/images/pochette_saintpierre.jpg',
    'nougaro': 'assets/images/salle_nougaro.png',
    'taquin': 'assets/images/salle_taquin.png',
    'rex': 'assets/images/pochette_rex.jpg',
    'interference': 'assets/images/salle_interference.jpg',
    'auditorium': 'assets/images/salle_auditorium.jpg',
    'chapelle du chu': 'assets/images/salle_chapelle.png',
    'hotel-dieu': 'assets/images/salle_chapelle.png',
    'palais consulaire': 'assets/images/salle_palaisconsulaire.jpg',
    'chapelle des carmelites': 'assets/images/salle_chapelle.png',
    // ── Salles de spectacle ──
    'casino barriere': 'assets/images/casino_barriere.jpg',
    'hall 8': 'assets/images/hall8.jpg',
    'espace job': 'assets/images/espacejob.jpg',
    'bascala': 'assets/images/bascala.jpg',
    // ── Clubs / Discotheques ──
    'nine club': 'assets/images/sc_discotheque.png',
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

    final dateLabel = event.dateDebut.isNotEmpty
        ? (event.dateFin.isNotEmpty && event.dateFin != event.dateDebut
            ? '${_formatDateShort(event.dateDebut)} - ${_formatDateShort(event.dateFin)}'
            : _formatDateShort(event.dateDebut))
        : '';

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Pochette carrée à gauche ──
              Padding(
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildPochette(pochette),
                      ),
                    // Badge GRATUIT
                    if (event.isFree)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            boxShadow: AppShadows.neon(AppColors.magenta, blur: 6, y: 1),
                          ),
                          child: Text(
                            'GRATUIT',
                            style: GoogleFonts.geistMono(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Contenu à droite ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Titre
                      Text(
                        event.categorie.toLowerCase().contains('opera')
                            ? event.titre.toUpperCase()
                            : event.titre,
                        style: GoogleFonts.geist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          height: 1.2,
                          letterSpacing: -0.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Date + lieu
                      if (dateLabel.isNotEmpty || event.lieuNom.isNotEmpty)
                        Row(
                          children: [
                            if (dateLabel.isNotEmpty) ...[
                              Text(
                                dateLabel.toUpperCase(),
                                style: GoogleFonts.geistMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                  color: AppColors.textDim,
                                ),
                              ),
                              if (event.lieuNom.isNotEmpty)
                                Text(
                                  '  ·  ',
                                  style: GoogleFonts.geist(
                                    fontSize: 9,
                                    color: AppColors.textFaint,
                                  ),
                                ),
                            ],
                            if (event.lieuNom.isNotEmpty)
                              Flexible(
                                child: Text(
                                  event.lieuNom,
                                  style: GoogleFonts.geist(
                                    fontSize: 9.5,
                                    color: AppColors.textFaint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 3),

                      // Like + Share
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(likesProvider.notifier)
                                .toggle(
                                  event.identifiant,
                                  meta: LikeMetadata(
                                    title: event.titre,
                                    imageUrl: event.photoPath,
                                    category: event.categorie,
                                  ),
                                ),
                            child: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked
                                  ? AppColors.magenta
                                  : AppColors.textFaint,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _shareEvent(),
                            child: const Icon(
                              Icons.share_outlined,
                              color: AppColors.textFaint,
                              size: 14,
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
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final image = _resolveImage();
    EventFullscreenPopup.show(context, event, image);
  }

  static const _defaultPochette = 'assets/images/pochette_concert.png';

  /// Construit la pochette : URL réseau > fichier local > asset par défaut.
  Widget _buildPochette(String fallbackAsset) {
    final photo = event.photoPath;
    if (photo == null || photo.isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      );
    }

    // URL réseau (Supabase Storage ou autre) — avec cache disque.
    if (photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          cacheWidth: 300,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultPochette, fit: BoxFit.cover),
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          cacheWidth: 300,
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
        cacheWidth: 300,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      ),
    );
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
