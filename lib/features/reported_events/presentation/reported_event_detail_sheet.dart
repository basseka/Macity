import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_chat.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_poster_card.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_view_tracker.dart';

/// Bottom sheet de detail d'un signalement.
///
/// Affiche l'affiche en grand + description longue + tags + bouton "Y aller"
/// (ouvre Google Maps en navigation depuis la position courante).
class ReportedEventDetailSheet extends StatefulWidget {
  final ReportedEvent event;
  const ReportedEventDetailSheet({super.key, required this.event});

  @override
  State<ReportedEventDetailSheet> createState() =>
      _ReportedEventDetailSheetState();
}

class _ReportedEventDetailSheetState extends State<ReportedEventDetailSheet> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  ReportedEvent get event => widget.event;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openItinerary() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${event.lat},${event.lng}&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullPhoto(BuildContext context, List<String> photos, int initial) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _FullPhotoViewer(
          photos: photos,
          initialIndex: initial,
          liveLabel: event.generated?.timeLabel ?? 'LIVE',
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showFullVideo(BuildContext context, List<String> videos, int initial) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _FullVideoViewer(
          videos: videos,
          initialIndex: initial,
          liveLabel: event.generated?.timeLabel ?? 'LIVE',
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildReporterFooter() {
    final prenom = event.reporterPrenom;
    final contributors = event.contributors;
    final extra = contributors.length - 3;
    final stackList = contributors.take(3).toList();

    final label = (prenom != null && prenom.isNotEmpty)
        ? 'Signale par $prenom${contributors.length > 1 ? " et ${contributors.length - 1} autre${contributors.length - 1 > 1 ? "s" : ""}" : ""}  \u00b7  ${_relativeAge()}'
        : 'Signale par la commu  \u00b7  ${_relativeAge()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (stackList.isNotEmpty)
            _AvatarStack(contributors: stackList, extraCount: extra > 0 ? extra : 0)
          else
            _SingleAvatar(url: event.reporterAvatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeAge() {
    final diff = DateTime.now().difference(event.createdAt);
    if (diff.inMinutes < 1) return 'a l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final g = event.generated;
    final mediaQuery = MediaQuery.of(context);
    final keyboard = mediaQuery.viewInsets.bottom;

    final maxH = keyboard > 0
        ? (mediaQuery.size.height - keyboard - mediaQuery.padding.top - 20)
        : mediaQuery.size.height * 0.78;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
      constraints: BoxConstraints(
        maxHeight: maxH,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F0FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Affiche poster (toujours visible)
                  Center(
                    child: ReportedEventViewTracker(
                      eventId: event.id,
                      child: ReportedEventPosterCard(
                        event: event,
                        width: mediaQuery.size.width - 32,
                        height: 220,
                      ),
                    ),
                  ),

                  // Galerie photos si plusieurs
                  if (event.photos.length > 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 14, color: Color(0xFF7B2D8E)),
                        const SizedBox(width: 6),
                        Text(
                          '${event.photos.length} photos de la commu',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A1259),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: event.photos.length,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemBuilder: (_, index) {
                          final isActive = index == _currentPage;
                          return AnimatedScale(
                            scale: isActive ? 1.0 : 0.88,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: GestureDetector(
                              onTap: () => _showFullPhoto(context, event.photos, index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _AnimatedBorderPhoto(
                                  isActive: isActive,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: event.photos[index],
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Miniatures synchronisees
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final isActive = index == _currentPage;
                          return GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF7B2D8E)
                                      : Colors.grey.shade300,
                                  width: isActive ? 2.5 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7B2D8E)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: event.photos[index],
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade200,
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Videos
                  if (event.videos.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.videocam, size: 14, color: Color(0xFF7B2D8E)),
                        const SizedBox(width: 6),
                        Text(
                          '${event.videos.length} video${event.videos.length > 1 ? 's' : ''} de la commu',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A1259),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.videos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _showFullVideo(context, event.videos, i),
                          child: SizedBox(
                            width: (mediaQuery.size.width - 32) / 3,
                            child: _VideoThumbnailCard(url: event.videos[i]),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Description longue
                  if (g != null && g.description.isNotEmpty) ...[
                    Text(
                      g.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A0A2E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Lieu
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF7B2D8E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.ville ?? 'Position GPS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1259),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Mood
                  if (g != null && g.mood.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Color(0xFF7B2D8E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          g.mood,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tags
                  if (g != null && g.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: g.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B2D8E)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A1259),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Footer "Signale par {prenom}" + avatar
                  _buildReporterFooter(),

                  const SizedBox(height: 14),

                  // Chat communautaire (auto-detruit a l'expiration de l'event)
                  ReportedEventChat(eventId: event.id),
                ],
              ),
            ),
          ),

          // CTA "Y aller" — masque quand le clavier est ouvert pour eviter
          // le chevauchement avec l'input du chat.
          if (keyboard == 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openItinerary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2D8E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: Text(
                      'Y aller',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

// ───────────────────────────────────────────
// Miniature video cliquable (pas de player, pas de conflit gesture)
// ───────────────────────────────────────────

class _VideoThumbnailCard extends StatefulWidget {
  final String url;
  const _VideoThumbnailCard({required this.url});

  @override
  State<_VideoThumbnailCard> createState() => _VideoThumbnailCardState();
}

class _VideoThumbnailCardState extends State<_VideoThumbnailCard> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {});
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Premiere frame de la video comme fond
          if (_ready && _ctrl != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _ctrl!.value.size.width,
                height: _ctrl!.value.size.height,
                child: VideoPlayer(_ctrl!),
              ),
            )
          else
            Container(color: Colors.grey.shade900),

          // Overlay sombre + bouton play
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Video player inline
// ───────────────────────────────────────────

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((e) {
        debugPrint('[VideoPlayer] init error: $e');
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _hasError
              ? Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off,
                            size: 28, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          'Video indisponible',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _initialized
                  ? AspectRatio(
                      aspectRatio: _ctrl.value.aspectRatio.clamp(0.5, 2.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _ctrl.value.isPlaying
                                ? _ctrl.pause()
                                : _ctrl.play();
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_ctrl),
                            AnimatedOpacity(
                              opacity: _ctrl.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B2D8E)
                                      .withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
        );
  }
}

// ───────────────────────────────────────────
// Viewer photo plein ecran (pinch to zoom + swipe)
// ───────────────────────────────────────────

class _FullPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String liveLabel;
  const _FullPhotoViewer({
    required this.photos,
    required this.initialIndex,
    this.liveLabel = 'LIVE',
  });

  @override
  State<_FullPhotoViewer> createState() => _FullPhotoViewerState();
}

class _FullPhotoViewerState extends State<_FullPhotoViewer> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photos swipables en plein ecran
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.photos[index],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // Badge LIVE
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: Center(
              child: _LiveBadgeOverlay(label: widget.liveLabel),
            ),
          ),

          // Bouton fermer
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Compteur
          if (widget.photos.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_current + 1} / ${widget.photos.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Viewer video plein ecran (swipe entre videos)
// ───────────────────────────────────────────

class _FullVideoViewer extends StatefulWidget {
  final List<String> videos;
  final int initialIndex;
  final String liveLabel;
  const _FullVideoViewer({
    required this.videos,
    required this.initialIndex,
    this.liveLabel = 'LIVE',
  });

  @override
  State<_FullVideoViewer> createState() => _FullVideoViewerState();
}

class _FullVideoViewerState extends State<_FullVideoViewer> {
  late PageController _pageCtrl;
  late int _current;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _initController(widget.initialIndex);
  }

  void _initController(int index) {
    if (_controllers.containsKey(index)) return;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videos[index]));
    _controllers[index] = ctrl;
    ctrl.initialize().then((_) {
      if (mounted) {
        setState(() {});
        ctrl.play();
      }
    });
  }

  void _onPageChanged(int index) {
    // Pause l'ancienne video
    _controllers[_current]?.pause();
    setState(() => _current = index);
    // Init et play la nouvelle
    _initController(index);
    _controllers[index]?.play();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, index) {
              final ctrl = _controllers[index];
              final initialized = ctrl?.value.isInitialized ?? false;

              return GestureDetector(
                onTap: () {
                  if (ctrl == null) return;
                  setState(() {
                    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                  });
                },
                child: Center(
                  child: initialized
                      ? AspectRatio(
                          aspectRatio: ctrl!.value.aspectRatio,
                          child: VideoPlayer(ctrl),
                        )
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          ),

          // Badge LIVE
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: Center(
              child: _LiveBadgeOverlay(label: widget.liveLabel),
            ),
          ),

          // Bouton fermer
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Compteur
          if (widget.videos.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_current + 1} / ${widget.videos.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ───────────────────────────────────────────
// Badge LIVE pour les viewers plein ecran
// ───────────────────────────────────────────

class _LiveBadgeOverlay extends StatefulWidget {
  final String label;
  const _LiveBadgeOverlay({required this.label});

  @override
  State<_LiveBadgeOverlay> createState() => _LiveBadgeOverlayState();
}

class _LiveBadgeOverlayState extends State<_LiveBadgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFDC2626),
                  const Color(0xFFDC2626).withValues(alpha: 0.2),
                  _ctrl.value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBorderPhoto extends StatefulWidget {
  final bool isActive;
  final Widget child;
  const _AnimatedBorderPhoto({required this.isActive, required this.child});

  @override
  State<_AnimatedBorderPhoto> createState() => _AnimatedBorderPhotoState();
}

class _AnimatedBorderPhotoState extends State<_AnimatedBorderPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: widget.child,
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF7B2D8E),
                const Color(0xFFE91E8C),
                _ctrl.value,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2D8E).withValues(alpha: 0.3 * _ctrl.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}


class _SingleAvatar extends StatelessWidget {
  final String? url;
  const _SingleAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    if (hasUrl) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.6), width: 1.5),
          image: DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 16),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<ReportedEventContributor> contributors;
  final int extraCount;
  const _AvatarStack({required this.contributors, this.extraCount = 0});

  static const double _size = 26;
  static const double _overlap = 9;

  @override
  Widget build(BuildContext context) {
    final total = contributors.length + (extraCount > 0 ? 1 : 0);
    final width = _size + (total - 1) * (_size - _overlap);
    return SizedBox(
      width: width,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < contributors.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: _circle(child: _innerAvatar(contributors[i].avatarUrl)),
            ),
          if (extraCount > 0)
            Positioned(
              left: contributors.length * (_size - _overlap),
              child: _circle(
                child: Container(
                  color: const Color(0xFF4A1259),
                  alignment: Alignment.center,
                  child: Text(
                    "+$extraCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(child: child),
    );
  }

  Widget _innerAvatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 14),
    );
  }
}
