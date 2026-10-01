import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:share_plus/share_plus.dart';

/// Diaporama plein ecran de l'album d'un event prive.
///
///  - lecture automatique (une photo toutes les [_slideDuration]) avec un
///    lent zoom avant (effet « Ken Burns »), en boucle ;
///  - glisser pour naviguer (met la lecture en pause), toucher l'image pour
///    afficher / masquer les commandes ;
///  - auteur, heure et legende de chaque photo ;
///  - « Enregistrer » : feuille de partage du systeme (Enregistrer l'image,
///    WhatsApp...), sans permission photo supplementaire.
class PhotoSlideshowScreen extends StatefulWidget {
  final List<PrivateEventPhoto> photos;
  final int initialIndex;
  final bool autoplay;
  final String eventTitle;

  const PhotoSlideshowScreen({
    super.key,
    required this.photos,
    required this.eventTitle,
    this.initialIndex = 0,
    this.autoplay = true,
  });

  static Future<void> open(
    BuildContext context, {
    required List<PrivateEventPhoto> photos,
    required String eventTitle,
    int initialIndex = 0,
    bool autoplay = true,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => PhotoSlideshowScreen(
          photos: photos,
          eventTitle: eventTitle,
          initialIndex: initialIndex,
          autoplay: autoplay,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<PhotoSlideshowScreen> createState() => _PhotoSlideshowScreenState();
}

class _PhotoSlideshowScreenState extends State<PhotoSlideshowScreen> {
  static const _slideDuration = Duration(seconds: 4);

  late final PageController _pager;
  late int _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
  late bool _playing = widget.autoplay && widget.photos.length > 1;
  bool _showUi = true;
  bool _saving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pager = PageController(initialPage: _index);
    if (_playing) _startTimer();
    // Precharge la photo suivante : pas de blanc pendant la lecture.
    WidgetsBinding.instance.addPostFrameCallback((_) => _precache(_index + 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pager.dispose();
    super.dispose();
  }

  void _precache(int i) {
    if (!mounted || widget.photos.isEmpty) return;
    final p = widget.photos[i % widget.photos.length];
    precacheImage(CachedNetworkImageProvider(p.imageUrl), context);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted || !_pager.hasClients) return;
      final next = (_index + 1) % widget.photos.length;
      if (next == 0) {
        _pager.jumpToPage(0); // boucle : retour direct au debut
      } else {
        _pager.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _save(BuildContext btnCtx) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Rect? origin;
    final box = btnCtx.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    try {
      final photo = widget.photos[_index];
      final file = await DefaultCacheManager().getSingleFile(photo.imageUrl);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/jpeg')],
        text: widget.eventTitle,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Impossible d\'enregistrer cette photo')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index];
    final author = (current.prenom?.trim().isNotEmpty ?? false) ? current.prenom!.trim() : 'Anonyme';
    final when = DateFormat("EEE d MMM 'à' HH'h'mm", 'fr_FR').format(current.createdAt.toLocal());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photos ──
          GestureDetector(
            onTap: () => setState(() => _showUi = !_showUi),
            // Glisser a la main met la lecture automatique en pause.
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (_playing && n.direction != ScrollDirection.idle) _togglePlay();
                return false;
              },
              child: PageView.builder(
              controller: _pager,
              itemCount: photos.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _precache(i + 1);
              },
              itemBuilder: (_, i) => _KenBurnsImage(
                url: photos[i].imageUrl,
                animate: _playing && i == _index,
                duration: _slideDuration,
              ),
            ),
            ),
          ),

          // ── Barre du haut ──
          AnimatedOpacity(
            opacity: _showUi ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showUi,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA000000), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 24),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.eventTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.geist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_index + 1} / ${photos.length}',
                                style: GoogleFonts.geist(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        if (photos.length > 1)
                          IconButton(
                            onPressed: _togglePlay,
                            tooltip: _playing ? 'Pause' : 'Lecture',
                            icon: Icon(
                              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        Builder(
                          builder: (btnCtx) => IconButton(
                            onPressed: () => _save(btnCtx),
                            tooltip: 'Enregistrer / partager',
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.download_rounded, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Auteur, heure, legende ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showUi ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.magenta,
                            backgroundImage: (current.avatarUrl?.isNotEmpty ?? false)
                                ? CachedNetworkImageProvider(current.avatarUrl!)
                                : null,
                            child: (current.avatarUrl?.isNotEmpty ?? false)
                                ? null
                                : Text(author[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            current.isHost ? '$author · organisateur' : author,
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(when, style: GoogleFonts.geist(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                      if (current.caption.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          current.caption.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.geist(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo en plein ecran (contenue, fond noir) avec lent zoom avant pendant
/// la lecture automatique.
class _KenBurnsImage extends StatelessWidget {
  final String url;
  final bool animate;
  final Duration duration;

  const _KenBurnsImage({
    required this.url,
    required this.animate,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
      ),
    );
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$url-$animate'),
        tween: Tween(begin: 1.0, end: animate ? 1.08 : 1.0),
        duration: animate ? duration : Duration.zero,
        curve: Curves.easeOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: image,
      ),
    );
  }
}
