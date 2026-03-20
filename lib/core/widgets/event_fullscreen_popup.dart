import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/day/presentation/share_event_sheet.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Popup plein ecran affichant la pochette en fond avec les infos overlayees.
class EventFullscreenPopup extends ConsumerWidget {
  final Event event;
  final String fallbackAsset;

  const EventFullscreenPopup({
    super.key,
    required this.event,
    required this.fallbackAsset,
  });

  static void show(BuildContext context, Event event, String fallbackAsset) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => EventFullscreenPopup(
        event: event,
        fallbackAsset: fallbackAsset,
      ),
    );
  }

  static final _displayDateFormat = DateFormat('dd/MM/yyyy');
  static const _defaultPochette = 'assets/images/pochette_concert.png';

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(likesProvider);
    final isLiked = likes.contains(event.identifiant);
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: const Color(0xFF1A1A2E),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Photo en haut (hauteur fixe) ──
                  SizedBox(
                    height: screenHeight * 0.35,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildFullPochette(),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        // Bouton fermer
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        // Badge gratuit
                        if (event.isFree)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E8C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'GRATUIT',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        // Titre sur la photo
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          child: Text(
                            event.categorie.toLowerCase().contains('opera')
                                ? event.titre.toUpperCase()
                                : event.titre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Infos scrollables en dessous ──
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          if (event.dateDebut.isNotEmpty)
                            _infoRow(
                              Icons.calendar_today,
                              event.dateFin.isNotEmpty && event.dateFin != event.dateDebut
                                  ? '${_formatDate(event.dateDebut)} - ${_formatDate(event.dateFin)}'
                                  : _formatDate(event.dateDebut),
                            ),
                          // Lieu
                          if (event.lieuNom.isNotEmpty)
                            _infoRow(Icons.location_on_outlined, event.lieuNom),
                          // Horaires
                          if (event.horaires.isNotEmpty)
                            _infoRow(Icons.access_time, event.horaires),

                          // Description
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.5,
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // ── Boutons actions ──
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _iconButton(
                                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                onTap: () => ref.read(likesProvider.notifier).toggle(
                                  event.identifiant,
                                  meta: LikeMetadata(
                                    title: event.titre,
                                    imageUrl: event.photoPath,
                                    category: event.categorie,
                                  ),
                                ),
                              ),
                              _actionButton(
                                icon: Icons.share_outlined,
                                label: 'Partager',
                                color: Colors.white,
                                onTap: () => _shareEvent(),
                              ),
                              _actionButton(
                                icon: Icons.people_alt_outlined,
                                label: 'Envoyer',
                                color: const Color(0xFF6C5CE7),
                                onTap: () => _shareInApp(context),
                              ),
                            ],
                          ),

                          // Billetterie
                          if (event.reservationUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => _openUrl(event.reservationUrl),
                                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                                label: const Text(
                                  'Billetterie',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E8C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _description {
    if (event.descriptifLong.isNotEmpty) return event.descriptifLong;
    if (event.descriptifCourt.isNotEmpty) return event.descriptifCourt;
    return '';
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la pochette plein ecran.
  Widget _buildFullPochette() {
    final photo = event.photoPath;
    if (photo == null || photo.isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      );
    }

    if (photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        width: double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultPochette, fit: BoxFit.cover),
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultPochette, fit: BoxFit.cover),
        ),
      );
    }

    return Image.file(
      File(photo),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      ),
    );
  }

  void _shareInApp(BuildContext context) {
    Navigator.of(context).pop(); // fermer le popup
    ShareEventSheet.show(
      context,
      eventId: event.identifiant,
      eventTitle: event.titre,
    );
  }

  void _shareEvent() {
    final buffer = StringBuffer();
    buffer.writeln(event.titre);
    if (event.dateDebut.isNotEmpty) buffer.writeln('Date: ${event.dateDebut}');
    if (event.lieuNom.isNotEmpty) buffer.writeln('Lieu: ${event.lieuNom}');
    if (event.isFree) buffer.writeln('Gratuit !');
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
    ActivityService.instance.eventSharedExternal(eventId: event.identifiant);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Impossible d\'ouvrir le lien: $e');
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Impossible d\'ouvrir le lien (fallback): $e');
      }
    }
  }
}
