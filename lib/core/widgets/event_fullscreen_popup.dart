import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/day/presentation/share_event_sheet.dart';
import 'package:pulz_app/features/day/presentation/boost_event_sheet.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Popup plein ecran affichant la pochette en fond avec les infos overlayees.
class EventFullscreenPopup extends ConsumerWidget {
  final Event event;
  final String fallbackAsset;
  final bool isPaged;
  final String? badge;

  const EventFullscreenPopup({
    super.key,
    required this.event,
    required this.fallbackAsset,
    this.isPaged = false,
    this.badge,
  });

  static Future<void> show(BuildContext context, Event event, String fallbackAsset) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => EventFullscreenPopup(
        event: event,
        fallbackAsset: fallbackAsset,
      ),
    );
  }

  /// Ouvre le popup avec swipe vertical entre les events.
  static Future<void> showPaged(
    BuildContext context, {
    required List<Event> events,
    required int initialIndex,
    required String Function(Event) fallbackAssetBuilder,
    String? badge,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _PagedEventPopup(
        events: events,
        initialIndex: initialIndex,
        fallbackAssetBuilder: fallbackAssetBuilder,
        badge: badge,
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: isPaged ? 10 : 20,
          right: isPaged ? 10 : 20,
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 0,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight),
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
              color: AppColors.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Photo en haut (hauteur fixe) ──
                  SizedBox(
                    height: screenHeight * 0.40,
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
                        // Badge "A la une" / "Au top"
                        if (badge != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                boxShadow: AppShadows.neon(
                                  AppColors.magenta,
                                  blur: 14,
                                  y: 4,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    badge == 'A la une' ? Icons.star : Icons.trending_up,
                                    size: 14, color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    badge!.toUpperCase(),
                                    style: GoogleFonts.geistMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Bouton fermer (decale si badge)
                        Positioned(
                          top: badge != null ? 42 : 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.bg.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        // Badge gratuit (decale si badge)
                        if (event.isFree)
                          Positioned(
                            top: badge != null ? 42 : 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                                boxShadow: AppShadows.neon(AppColors.magenta, blur: 8, y: 2),
                              ),
                              child: Text(
                                'GRATUIT',
                                style: GoogleFonts.geistMono(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        // Titre sur la photo
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Text(
                            event.categorie.toLowerCase().contains('opera')
                                ? event.titre.toUpperCase()
                                : event.titre,
                            style: GoogleFonts.geist(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                              shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Infos en dessous (scrollable) ──
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                          // Horaires : pills si multi-séances (cinéma),
                          // sinon ligne classique.
                          if (event.horaires.isNotEmpty)
                            event.horaires.contains(',')
                                ? _horairesChips(event.horaires)
                                : _infoRow(Icons.access_time, event.horaires),

                          // Organisateur (pro)
                          if (event.organisateurNom.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 15,
                                    color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Par ${event.organisateurNom}',
                                      style: GoogleFonts.geist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Description
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _description,
                              style: GoogleFonts.geist(
                                fontSize: 13,
                                color: AppColors.textDim,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Boutons actions fixes ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, event.reservationUrl.isNotEmpty ? 8 : 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _iconButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.magenta : AppColors.text,
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
                          color: AppColors.text,
                          onTap: () => _shareEvent(),
                        ),
                        _actionButton(
                          icon: Icons.people_alt_outlined,
                          label: 'Envoyer',
                          color: AppColors.violet,
                          onTap: () => _shareInApp(context),
                        ),
                      ],
                    ),
                  ),

                  // ── Billetterie fixe en bas ──
                  if (event.reservationUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: SizedBox(
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
                            backgroundColor: AppColors.magenta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.iconBtn),
                            ),
                            elevation: 0,
                          ).copyWith(
                            textStyle: WidgetStatePropertyAll(
                              GoogleFonts.geist(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.magenta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Horaires sous forme de chips (pour les séances cinéma / multi-horaires).
  Widget _horairesChips(String raw) {
    final times = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: AppColors.magenta),
              const SizedBox(width: 8),
              Text(
                times.length > 1 ? '${times.length} séances' : 'Séance',
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: times.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.magenta.withValues(alpha: 0.35)),
              ),
              child: Text(
                t,
                style: GoogleFonts.geist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            )).toList(),
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.geist(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la pochette plein ecran (image ou video).
  Widget _buildFullPochette() {
    // Si video, afficher le player
    if (event.videoUrl != null && event.videoUrl!.isNotEmpty) {
      return _EventVideoPlayer(videoUrl: event.videoUrl!);
    }

    final photo = event.photoPath;
    if (photo == null || photo.isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        cacheWidth: 300,
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
          cacheWidth: 300,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultPochette, fit: BoxFit.cover),
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          cacheWidth: 300,
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
        cacheWidth: 300,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultPochette, fit: BoxFit.cover),
      ),
    );
  }

  /// Un event utilisateur a un identifiant UUID (pas de préfixe scraper).
  bool _isUserEvent(Event e) {
    final id = e.identifiant;
    // Les scraped events ont des préfixes comme "3t_", "toulouse_", "billetreduc_", etc.
    // Les user events ont un UUID (36 chars avec tirets)
    return id.length == 36 && id.contains('-') && !id.startsWith('3t_');
  }

  void _boostEvent(BuildContext context) {
    Navigator.of(context).pop();
    BoostEventSheet.show(
      context,
      eventId: event.identifiant,
      eventTitle: event.titre,
      eventDate: event.dateDebut,
      currentPriority: 'P4',
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
    buffer.writeln('\nDecouvre sur MaCity :');
    final link = 'https://macity.app/event/${Uri.encodeComponent(event.identifiant)}';
    buffer.writeln(link);
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

/// Video player plein ecran dans le popup event.
class _EventVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _EventVideoPlayer({required this.videoUrl});

  @override
  State<_EventVideoPlayer> createState() => _EventVideoPlayerState();
}

class _EventVideoPlayerState extends State<_EventVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(1.0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          // Play/pause overlay
          if (!_controller.value.isPlaying)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
          // Mute button
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _muted = !_muted;
                  _controller.setVolume(_muted ? 0 : 1);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper qui affiche les events dans un PageView swipeable.
class _PagedEventPopup extends StatefulWidget {
  final List<Event> events;
  final int initialIndex;
  final String Function(Event) fallbackAssetBuilder;
  final String? badge;

  const _PagedEventPopup({
    required this.events,
    required this.initialIndex,
    required this.fallbackAssetBuilder,
    this.badge,
  });

  @override
  State<_PagedEventPopup> createState() => _PagedEventPopupState();
}

class _PagedEventPopupState extends State<_PagedEventPopup> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: widget.events.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) {
            final event = widget.events[i];
            return EventFullscreenPopup(
              event: event,
              fallbackAsset: widget.fallbackAssetBuilder(event),
              isPaged: true,
              badge: widget.badge,
            );
          },
        ),
        // Indicateur de position (a droite, vertical)
        if (widget.events.length > 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Container(width: 1, height: 8, color: Colors.white38),
                    Text(
                      '${widget.events.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Fleche swipe up hint
        if (_currentIndex < widget.events.length - 1)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.keyboard_arrow_up, size: 28, color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
      ],
    );
  }
}
