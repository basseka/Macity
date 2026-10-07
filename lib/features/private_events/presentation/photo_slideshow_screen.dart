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
import 'package:pulz_app/core/services/analytics_service.dart';

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

  /// Photos que l'utilisateur peut retirer (organisateur : toutes ; sinon
  /// les siennes). Null : pas de bouton de suppression.
  final bool Function(PrivateEventPhoto photo)? canDelete;

  /// Retire la photo (confirmation comprise) ; true si retiree.
  final Future<bool> Function(PrivateEventPhoto photo)? onDelete;

  const PhotoSlideshowScreen({
    super.key,
    required this.photos,
    required this.eventTitle,
    this.initialIndex = 0,
    this.autoplay = true,
    this.canDelete,
    this.onDelete,
  });

  static Future<void> open(
    BuildContext context, {
    required List<PrivateEventPhoto> photos,
    required String eventTitle,
    int initialIndex = 0,
    bool autoplay = true,
    bool Function(PrivateEventPhoto photo)? canDelete,
    Future<bool> Function(PrivateEventPhoto photo)? onDelete,
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
          canDelete: canDelete,
          onDelete: onDelete,
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
  /// Copie locale : une photo retiree disparait du diaporama sans le fermer.
  late final List<PrivateEventPhoto> _photos = [...widget.photos];
  late int _index = widget.initialIndex.clamp(0, _photos.length - 1);
  late bool _playing = widget.autoplay && _photos.length > 1;
  bool _saving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('/event-prive/diaporama');
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
    if (!mounted || _photos.isEmpty) return;
    final p = _photos[i % _photos.length];
    precacheImage(CachedNetworkImageProvider(p.imageUrl), context);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted || !_pager.hasClients) return;
      final next = (_index + 1) % _photos.length;
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
      final photo = _photos[_index];
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

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _photos.isEmpty) return;
    if (_playing) _togglePlay();
    final photo = _photos[_index];
    final removed = await onDelete(photo);
    if (!mounted || !removed) return;
    if (_photos.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _photos.removeAt(_index);
      if (_index >= _photos.length) _index = _photos.length - 1;
    });
    _pager.jumpToPage(_index);
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final current = photos[_index];
    final author = (current.prenom?.trim().isNotEmpty ?? false) ? current.prenom!.trim() : 'Anonyme';
    final when = DateFormat("EEE d MMM 'à' HH'h'mm", 'fr_FR').format(current.createdAt.toLocal());

    return Scaffold(
      backgroundColor: Colors.black,
      // Mise en page en 3 bandes : boutons EN HAUT, photo au milieu, auteur
      // et legende EN BAS. Rien n'est pose sur la photo.
      body: SafeArea(
        child: Column(
          children: [
            // ── Bande du haut : fermer, titre, lecture, corbeille, enregistrer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
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
                  if (widget.onDelete != null && (widget.canDelete?.call(current) ?? false))
                    IconButton(
                      onPressed: _delete,
                      tooltip: 'Retirer de l\'album',
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
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

            // ── Photo : glisser pour naviguer (met la lecture en pause) ──
            Expanded(
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
                  itemBuilder: (_, i) => ClipRect(
                    child: _KenBurnsImage(
                      url: photos[i].imageUrl,
                      animate: _playing && i == _index,
                      duration: _slideDuration,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bande du bas : auteur, heure, legende ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                      Flexible(
                        child: Text(
                          current.isHost ? '$author · organisateur' : author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
          ],
        ),
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
