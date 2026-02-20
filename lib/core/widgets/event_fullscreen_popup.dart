import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
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
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // ── Pochette plein fond ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: _buildFullPochette()),
                  ],
                ),

                // ── Gradient overlay en bas ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenu overlay ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermer
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Badge emoji + gratuit
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            event.categoryEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          if (event.isFree) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E8C),
                                borderRadius: BorderRadius.circular(12),
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
                          ],
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Infos en bas ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Titre
                          Text(
                            event.titre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Date
                          if (event.dateDebut.isNotEmpty)
                            _infoRow(
                              Icons.calendar_today,
                              event.dateFin.isNotEmpty &&
                                      event.dateFin != event.dateDebut
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
                            const SizedBox(height: 8),
                            Text(
                              _description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── Boutons actions ──
                          Row(
                            children: [
                              // Like
                              _actionButton(
                                icon: isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: isLiked ? 'Aimé' : 'Aimer',
                                color: isLiked
                                    ? Colors.red
                                    : Colors.white,
                                onTap: () => ref
                                    .read(likesProvider.notifier)
                                    .toggle(event.identifiant),
                              ),
                              const SizedBox(width: 12),
                              // Share
                              _actionButton(
                                icon: Icons.share_outlined,
                                label: 'Partager',
                                color: Colors.white,
                                onTap: () => _shareEvent(),
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
                                onPressed: () =>
                                    _openUrl(event.reservationUrl),
                                icon: const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Billetterie',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E8C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _description {
    if (event.descriptifCourt.isNotEmpty) return event.descriptifCourt;
    if (event.descriptifLong.isNotEmpty) return event.descriptifLong;
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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

  void _shareEvent() {
    final buffer = StringBuffer();
    buffer.writeln(event.titre);
    if (event.dateDebut.isNotEmpty) buffer.writeln('Date: ${event.dateDebut}');
    if (event.lieuNom.isNotEmpty) buffer.writeln('Lieu: ${event.lieuNom}');
    if (event.isFree) buffer.writeln('Gratuit !');
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
