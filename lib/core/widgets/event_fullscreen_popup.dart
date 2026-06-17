import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, rootBundle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/fullscreen_image_viewer.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/engagement/domain/event_source_detector.dart';
import 'package:pulz_app/features/engagement/presentation/event_engagement_sheet.dart';
import 'package:pulz_app/features/engagement/state/event_engagement_provider.dart';

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
  static const _defaultPochette = 'assets/images/pochette_concert.webp';

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Fix : remplit toute la hauteur disponible jusqu'a la nav bar
            // inferieure du systeme. Avant : Column mainAxisSize.min faisait
            // shrinker le popup a la taille du contenu.
            height: screenHeight - MediaQuery.of(context).padding.top - 8,
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  // ── Photo en haut (mode affiche plein ecran) ──
                  SizedBox(
                    height: screenHeight * 0.55,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildFullPochette(context),
                        // Gradient overlay : IgnorePointer pour ne pas
                        // bloquer les taps sur les boutons en dessous (mute,
                        // fullscreen). Sans ca, le Container avec decoration
                        // gradient peut capturer le pointer event et empecher
                        // le hit-test de descendre jusqu'au video player.
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x33000000),
                                  Color(0x99000000),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Petit badge discret "A la une" / "Au top" en haut-gauche
                        if (badge != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bg.withValues(alpha: 0.6),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.chip),
                                border: Border.all(
                                  color: AppColors.magenta.withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    badge == 'A la une'
                                        ? Icons.star
                                        : Icons.trending_up,
                                    size: 11,
                                    color: AppColors.magenta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    badge!.toUpperCase(),
                                    style: GoogleFonts.geistMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
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
                        // Badge gratuit (decale sous le badge "A la une" si present)
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

                  // ── Infos en dessous (scrollable, prend la hauteur restante) ──
                  Expanded(
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
                          // Lieu + bouton info (ouvre une fiche detaillee
                          // par-dessus, sans fermer le popup courant)
                          if (event.lieuNom.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.magenta,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.lieuNom,
                                      style: GoogleFonts.geist(
                                        fontSize: 13,
                                        color: AppColors.text,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        _openInfoSheet(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.magenta
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.magenta
                                              .withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 12,
                                            color: AppColors.magenta,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Infos',
                                            style: GoogleFonts.geist(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.magenta,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

                          // Description (tronquee + "plus" pour deplier)
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _ExpandableDescription(text: _description),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Actions like / comment / partage (espacees, tap separe) ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      event.reservationUrl.isNotEmpty
                          ? 4
                          : 8 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: _EngagementActionsBar(
                      eventSource: detectEventSource(event.identifiant),
                      eventIdentifiant: event.identifiant,
                      eventTitle: event.titre,
                      photoUrl: event.photoPath,
                      fallbackAsset: fallbackAsset,
                    ),
                  ),

                  // ── Billetterie fixe en bas ──
                  if (event.reservationUrl.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        // Respect home indicator / gesture nav bar
                        16 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _openUrl(event.reservationUrl),
                          icon: const Icon(Icons.confirmation_number_outlined, size: 14),
                          label: const Text('Billetterie'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.magenta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.iconBtn),
                            ),
                            elevation: 0,
                          ).copyWith(
                            textStyle: WidgetStatePropertyAll(
                              GoogleFonts.geist(
                                fontSize: 12,
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

  /// Ouvre une fiche detaillee par-dessus le popup (sans le fermer). Affiche
  /// tous les champs de l'event dans une vue scrollable pour une lecture
  /// confortable de la description complete.
  void _openInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetCtx) => _EventInfoSheet(event: event),
    );
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

  /// Construit la pochette plein ecran (image ou video).
  ///
  /// Pour une affiche image (pas video, pas placeholder), un tap ouvre le
  /// viewer plein ecran zoomable. La video garde sa propre logique (play/pause
  /// + bouton fullscreen dedie).
  Widget _buildFullPochette(BuildContext context) {
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

    final isNetwork = photo.startsWith('http');
    final Widget image = isNetwork
        ? CachedNetworkImage(
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
          )
        : Image.file(
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

    // Tap sur l'affiche -> plein ecran zoomable.
    return GestureDetector(
      onTap: () => showFullscreenImage(
        context,
        imageUrl: isNetwork ? photo : null,
        imageFile: isNetwork ? null : photo,
        imageAsset: fallbackAsset,
      ),
      child: image,
    );
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
  int _fsTapCount = 0;

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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video + tap play/pause : GestureDetector enveloppe SEULEMENT
        // la video (pas toute la Stack), sinon il gagnait l'arene des
        // gestures sur les boutons (mute/fullscreen) → tap ignore.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        // Play/pause overlay : IgnorePointer pour ne pas capter les taps
        // (on veut que ce soit la video derriere qui les recoive).
        if (!_controller.value.isPlaying)
          const IgnorePointer(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
          ),
        // Mute en bas a droite
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _muted = !_muted;
                _controller.setVolume(_muted ? 0 : 1);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),

        // Fullscreen au CENTRE a DROITE de l'affiche. Material+InkWell
        // au lieu de GestureDetector pour fiabilite tactile. Hit area
        // 44x44 (recommandation Material).
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // DEBUG : incremente le compteur visible dans le bouton
                    // pour prouver visuellement que le tap arrive bien.
                    setState(() => _fsTapCount++);
                    HapticFeedback.heavyImpact();
                    debugPrint('[fullscreen] tap #$_fsTapCount fired');
                    _openFullscreen(context);
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        // DEBUG : badge rouge avec compteur de taps.
                        // Si tu vois ce nombre augmenter au tap, le tap fire
                        // bien -> probleme = Navigator.push.
                        // Sinon le tap est intercepte ailleurs.
                        if (_fsTapCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_fsTapCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
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
          ),
        ),
      ],
    );
  }

  /// Pousse un viewer plein ecran (route dediee) qui reutilise le meme
  /// VideoPlayerController — pas de rechargement reseau, position et son
  /// preserves au retour.
  Future<void> _openFullscreen(BuildContext context) async {
    // Pause le player inline pendant la fullscreen pour eviter double-audio
    // ET liberer la texture (sinon la vue plein ecran reste noire sur Android
    // tant que le VideoPlayer inline est monte sur le meme controller).
    final wasPlaying = _controller.value.isPlaying;
    final startAt = _controller.value.position;
    _controller.pause();
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoView(
          videoUrl: widget.videoUrl,
          startAt: startAt,
          muted: _muted,
        ),
      ),
    );
    if (!mounted) return;
    // Reprend la lecture inline au retour si elle tournait avant.
    setState(() {
      if (wasPlaying) _controller.play();
    });
  }
}

/// Vue plein ecran d'une video : noir, video centree, tap = play/pause,
/// bouton close (X) en haut. Reutilise le controller passe en parametre
/// (pas de dispose ici — le proprietaire reste l'appelant).
class _FullscreenVideoView extends StatefulWidget {
  final String videoUrl;
  final Duration startAt;
  final bool muted;
  const _FullscreenVideoView({
    required this.videoUrl,
    required this.startAt,
    required this.muted,
  });

  @override
  State<_FullscreenVideoView> createState() => _FullscreenVideoViewState();
}

class _FullscreenVideoViewState extends State<_FullscreenVideoView> {
  late VideoPlayerController _ctrl;
  bool _muted = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..addListener(_onTick)
      ..initialize().then((_) async {
        if (!mounted) return;
        await _ctrl.seekTo(widget.startAt);
        await _ctrl.setVolume(_muted ? 0 : 1);
        await _ctrl.play();
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = _ctrl.value.size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video centree avec aspect ratio reel
            Center(
              child: !_ready
                  ? const CircularProgressIndicator(color: Color(0xFFE91E8C))
                  : AspectRatio(
                aspectRatio: size.width > 0 && size.height > 0
                    ? size.width / size.height
                    : 16 / 9,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_ctrl.value.isPlaying) {
                      _ctrl.pause();
                    } else {
                      _ctrl.play();
                    }
                  },
                  child: Stack(
                    children: [
                      VideoPlayer(_ctrl),
                      if (!_ctrl.value.isPlaying)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Close button top-right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            // Mute + position en bas
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _muted = !_muted;
                        _ctrl.setVolume(_muted ? 0 : 1);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _muted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Barre de progression
                  Expanded(
                    child: VideoProgressIndicator(
                      _ctrl,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFE91E8C),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

class _PagedEventPopupState extends State<_PagedEventPopup>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
  bool _hintsVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Animation de rebond pour faire pulser les chevrons (up/down) et
    // suggerer fortement le swipe vertical.
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    // Cache les hints apres 4s — on a montre l'affordance, place au contenu.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _hintsVisible = false);
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
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
        // Hints "Swiper" en haut et bas — chevrons animes qui rebondent
        // pour montrer clairement qu'on peut swiper verticalement.
        // Visibles 4 secondes au moment de l'ouverture puis fade out.
        if (widget.events.length > 1) ...[
          // Top : "Story precedente" (visible si on n'est PAS sur la 1ere)
          if (_currentIndex > 0)
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _hintsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, -_bounceAnim.value),
                      child: _SwipeHint(
                        icon: Icons.keyboard_arrow_up_rounded,
                        label: 'Story précédente',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Bottom : "Swipe pour la suivante" (visible si on n'est PAS sur
          // la derniere — c'est l'affordance principale).
          if (_currentIndex < widget.events.length - 1)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _hintsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: _SwipeHint(
                        icon: Icons.keyboard_arrow_down_rounded,
                        label: 'Swipe pour la suivante',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Pill compacte "icon + label" affichee comme hint de swipe vertical.
/// Fond noir semi-transparent + texte blanc + glow violet leger.
class _SwipeHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SwipeHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    // IgnorePointer : ce hint est purement decoratif et centre en bas, pile
    // au-dessus du bouton "Billetterie". Sans ca, la pastille capte les taps
    // au centre du bouton (centre mort, cf. bug iOS/Android). Cf. le gradient
    // plus haut qui utilise deja IgnorePointer pour la meme raison.
    return IgnorePointer(
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.32),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// =============================================================================
// Description tronquee avec lien "plus" pour deplier in-place.
// =============================================================================
class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _collapsedMaxChars = 140;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    final shouldTruncate = text.length > _collapsedMaxChars;
    final baseStyle = GoogleFonts.geist(
      fontSize: 13,
      color: AppColors.textDim,
      height: 1.5,
    );

    if (!shouldTruncate || _expanded) {
      return Text(text, style: baseStyle);
    }

    final preview = text.substring(0, _collapsedMaxChars).trimRight();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$preview… ', style: baseStyle),
          TextSpan(
            text: 'plus',
            style: GoogleFonts.geist(
              fontSize: 13,
              color: AppColors.magenta,
              fontWeight: FontWeight.w700,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => setState(() => _expanded = true),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Barre d'actions Like / Comment / Share avec 3 zones de tap separees.
// =============================================================================
class _EngagementActionsBar extends ConsumerStatefulWidget {
  final String eventSource;
  final String eventIdentifiant;
  final String eventTitle;
  final String? photoUrl;
  final String fallbackAsset;

  const _EngagementActionsBar({
    required this.eventSource,
    required this.eventIdentifiant,
    required this.eventTitle,
    required this.photoUrl,
    required this.fallbackAsset,
  });

  @override
  ConsumerState<_EngagementActionsBar> createState() =>
      _EngagementActionsBarState();
}

class _EngagementActionsBarState extends ConsumerState<_EngagementActionsBar> {
  // Photo prete a etre partagee, resolue en arriere-plan a l'ouverture du
  // popup. Permet un tap instantane sur le bouton "partage" (sinon le premier
  // tap doit attendre le download + le copy temp, et le user re-tape plusieurs
  // fois avant que la share-sheet Android n'apparaisse).
  XFile? _sharePhoto;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(engagementTotalsProvider.notifier);
      notifier.request(widget.eventSource, widget.eventIdentifiant);
      notifier.loadUserLiked(widget.eventSource, widget.eventIdentifiant);
      // Lance le pre-fetch de la photo de partage sans bloquer le build.
      _prefetchSharePhoto();
    });
  }

  Future<void> _prefetchSharePhoto() async {
    try {
      final file =
          await _resolvePhotoFile(widget.photoUrl, widget.fallbackAsset);
      if (!mounted) return;
      setState(() => _sharePhoto = file);
    } catch (e) {
      debugPrint('[share] prefetch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(engagementTotalsProvider);
    final key = engagementKey(widget.eventSource, widget.eventIdentifiant);
    final totals = state.totals[key];
    final liked = state.userLiked[key] ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionTile(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          iconColor: liked ? AppColors.magenta : AppColors.text,
          count: totals?.likesCount ?? 0,
          onTap: () => ref
              .read(engagementTotalsProvider.notifier)
              .toggleLike(widget.eventSource, widget.eventIdentifiant),
        ),
        _actionTile(
          icon: Icons.mode_comment_outlined,
          iconColor: AppColors.text,
          count: totals?.commentsCount ?? 0,
          onTap: () => EventEngagementSheet.show(
            context,
            eventSource: widget.eventSource,
            eventIdentifiant: widget.eventIdentifiant,
            eventTitle: widget.eventTitle,
          ),
        ),
        _actionTile(
          icon: Icons.send_outlined,
          iconColor: AppColors.text,
          count: totals?.sharesCount ?? 0,
          loading: _sharing,
          onTap: _onShareTap,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required int count,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.magenta,
                ),
              )
            else
              Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 6),
            Text(
              _formatCount(count),
              style: GoogleFonts.geistMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n < 1000) return n.toString();
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000).round()}k';
  }

  Future<void> _onShareTap() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // App Link https vers l'event : cliquable dans les messageries (WhatsApp
      // ne rend cliquable que les liens http/https, jamais un scheme custom).
      // macity.app/event/* a assetlinks autoVerify -> tap ouvre l'app si
      // installee, sinon la page web propose l'app + le Play Store.
      final deepLink = 'https://macity.app/event/${widget.eventIdentifiant}';
      final caption =
          '${widget.eventTitle}\n\nDécouvre cet évènement sur MaCity 👇\n$deepLink';

      // Utilise la photo pre-resolue si dispo (cas usuel). Sinon resout
      // maintenant avec un timeout court pour ne pas bloquer l'utilisateur.
      // Prefetch pas encore fini : on laisse jusqu'a 9s au download de la
      // vraie affiche, puis on retombe sur la pochette locale. Le timeout
      // est INTERNE a _resolvePhotoFile et ne borne QUE le reseau -> le
      // fallback image locale est toujours atteint, jamais de texte brut.
      final photo = _sharePhoto ??
          await _resolvePhotoFile(
            widget.photoUrl,
            widget.fallbackAsset,
            networkTimeout: const Duration(seconds: 9),
          );

      if (photo != null) {
        await Share.shareXFiles(
          [photo],
          text: caption,
          subject: widget.eventTitle,
        );
      } else {
        await Share.share(caption, subject: widget.eventTitle);
      }
      if (!mounted) return;
      ref
          .read(engagementTotalsProvider.notifier)
          .recordShare(widget.eventSource, widget.eventIdentifiant);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Resout une image (URL reseau ou asset local) vers un XFile partageable.
  /// Priorise l'URL reseau (image specifique a l'event). Tombe sur l'asset
  /// fallback si pas de URL ou si le download echoue.
  /// [networkTimeout] borne UNIQUEMENT le download reseau. null = pas de
  /// limite (cas du prefetch : il continue de chercher la vraie affiche en
  /// tache de fond). Dans tous les cas, en cas d'echec/timeout reseau on
  /// retombe sur l'image locale -> on ne renvoie jamais null a cause du
  /// reseau, donc jamais de partage en texte brut.
  Future<XFile?> _resolvePhotoFile(
    String? url,
    String assetPath, {
    Duration? networkTimeout,
  }) async {
    if (url != null && url.startsWith('http')) {
      try {
        final download = DefaultCacheManager().getSingleFile(url);
        final file = networkTimeout == null
            ? await download
            : await download.timeout(networkTimeout);
        if (await file.exists() && await file.length() > 0) {
          return XFile(file.path);
        }
      } catch (e) {
        debugPrint('[share] network photo download failed/timeout: $e');
      }
    }
    return _copyAssetToTemp(assetPath);
  }

  Future<XFile?> _copyAssetToTemp(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final dir = await getTemporaryDirectory();
      final ext = assetPath.split('.').last;
      final out = File('${dir.path}/macity_share.$ext');
      await out.writeAsBytes(bytes.buffer.asUint8List());
      return XFile(out.path);
    } catch (e) {
      debugPrint('[share] asset copy failed: $e');
      return null;
    }
  }
}

// =============================================================================
// Fiche detaillee (bottom sheet ouvert PAR-DESSUS le popup, sans le fermer).
// Affiche tous les champs avec la description complete scrollable, pour une
// lecture confortable du texte sans ouvrir une autre page.
// =============================================================================
class _EventInfoSheet extends StatelessWidget {
  final Event event;

  const _EventInfoSheet({required this.event});

  static final _displayDateFormat = DateFormat('dd/MM/yyyy');

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  String get _description {
    if (event.descriptifLong.isNotEmpty) return event.descriptifLong;
    if (event.descriptifCourt.isNotEmpty) return event.descriptifCourt;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Grabber
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre + close
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.titre,
                        style: GoogleFonts.geist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.textDim,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.line),
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    20 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta : date / lieu / horaires / organisateur / prix
                      if (event.dateDebut.isNotEmpty)
                        _metaRow(
                          Icons.calendar_today,
                          event.dateFin.isNotEmpty &&
                                  event.dateFin != event.dateDebut
                              ? '${_formatDate(event.dateDebut)} - ${_formatDate(event.dateFin)}'
                              : _formatDate(event.dateDebut),
                        ),
                      if (event.lieuNom.isNotEmpty)
                        _metaRow(Icons.location_on_outlined, event.lieuNom),
                      if (event.horaires.isNotEmpty)
                        _metaRow(Icons.access_time, event.horaires),
                      if (event.organisateurNom.isNotEmpty)
                        _metaRow(
                          Icons.verified,
                          'Par ${event.organisateurNom}',
                          color: const Color(0xFFFBBF24),
                        ),
                      if (event.isFree)
                        _metaRow(Icons.local_offer_outlined, 'Gratuit'),
                      const SizedBox(height: 18),
                      // Description complete (pas de troncature ici)
                      if (_description.isNotEmpty) ...[
                        Text(
                          'À propos',
                          style: GoogleFonts.geist(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDim,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _description,
                          style: GoogleFonts.geist(
                            fontSize: 14,
                            color: AppColors.text,
                            height: 1.55,
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Aucune description fournie pour cet évènement.',
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              color: AppColors.textFaint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.magenta),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.geist(
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
