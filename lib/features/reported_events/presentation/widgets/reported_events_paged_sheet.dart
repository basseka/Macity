import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/reported_event_detail_sheet.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/story_video_cache.dart';
import 'package:pulz_app/features/reported_events/state/chat_provider.dart';

/// Un media (photo ou video) d'une story, normalise pour le viewer.
class _StoryMediaItem {
  final String url;
  final bool isVideo;
  const _StoryMediaItem({required this.url, required this.isVideo});
}

/// Extrait le timestamp ms du nom de fichier `<ts>_report.{jpg|mp4}` upload
/// par [reported_events_service]. Retourne 0 si l'URL ne match pas le pattern
/// (placeholders, fakes, sources externes) — la sort stable de Dart preserve
/// alors l'ordre d'apparition dans les listes photos/videos.
final RegExp _mediaTsRegex = RegExp(r'(\d{10,15})_report\.(jpg|mp4|jpeg|png|webp)');
int _mediaCaptureTs(String url) {
  final m = _mediaTsRegex.firstMatch(url);
  if (m == null) return 0;
  return int.tryParse(m.group(1)!) ?? 0;
}

/// Aplatit photos + videos d'un event en une liste FIFO par timestamp de
/// capture (extrait du nom de fichier `<ts>_report.<ext>`). Les medias sans
/// timestamp parseable retombent en queue dans l'ordre photos-puis-videos.
List<_StoryMediaItem> mediasOfEvent(ReportedEvent e) {
  final list = <_StoryMediaItem>[
    ...e.photos.map((u) => _StoryMediaItem(url: u, isVideo: false)),
    ...e.videos.map((u) => _StoryMediaItem(url: u, isVideo: true)),
  ];
  list.sort((a, b) => _mediaCaptureTs(a.url).compareTo(_mediaCaptureTs(b.url)));
  return list;
}

/// Viewer plein ecran style Snapchat / Instagram stories.
///
/// Comportement :
///  - progress bars segmentees en haut (1 segment par MEDIA de l'event courant,
///    remplissage temps reel)
///  - auto-advance media par media puis event suivant (5s par photo, duree
///    reelle par video capee a 30s)
///  - tap zone gauche (1/3) → media precedent (ou event precedent au dernier
///    media si on est au 1er media du courant)
///  - tap zone droite (2/3) → media suivant (ou event suivant au dernier media)
///  - long-press n'importe ou → pause progression + video
///  - swipe horizontal libre via PageView → saute l'event entier (UX Snap)
class ReportedEventsPagedSheet extends ConsumerStatefulWidget {
  final List<ReportedEvent> events;
  final int initialIndex;
  final bool initialScrollToChat;

  const ReportedEventsPagedSheet({
    super.key,
    required this.events,
    required this.initialIndex,
    this.initialScrollToChat = false,
  });

  /// Helper static : push en plein écran (style Insta stories).
  static Future<void> open(
    BuildContext context, {
    required List<ReportedEvent> events,
    required int initialIndex,
    bool initialScrollToChat = false,
  }) {
    debugPrint('[StoryViewer] open count=${events.length} initial=$initialIndex');
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReportedEventsPagedSheet(
          events: events,
          initialIndex: initialIndex,
          initialScrollToChat: initialScrollToChat,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReportedEventsPagedSheet> createState() =>
      _ReportedEventsPagedSheetState();
}

class _ReportedEventsPagedSheetState
    extends ConsumerState<ReportedEventsPagedSheet>
    with SingleTickerProviderStateMixin {
  /// Duree par defaut pour une photo (et pendant la resolution video).
  static const _photoDuration = Duration(seconds: 5);

  /// Cap pour les videos longues — au-dela on coupe pour preserver le rythme
  /// du flux story (le user peut quand meme tap-droite pour avancer).
  static const _maxVideoDuration = Duration(seconds: 30);

  late PageController _pageCtrl;
  late AnimationController _progress;
  late int _current;
  int _currentMediaIdx = 0;
  bool _isPaused = false;

  /// Sur un retour arriere a travers les events, on veut atterrir sur le
  /// DERNIER media de l'event precedent (UX Snap). On stocke ici l'index
  /// cible avant d'animer la PageView, [_onPageChanged] le consomme.
  int? _pendingMediaIdxOnArrival;

  /// Cache des medias par event (pour eviter de retrier a chaque tap).
  final Map<String, List<_StoryMediaItem>> _mediasCache = {};

  /// Cache des durees video resolues (cle = url) pour eviter de re-initialiser
  /// un VideoPlayerController en cas de re-visite.
  final Map<String, Duration> _videoDurations = {};

  /// Token monotone pour invalider une resolution de duree en cours quand
  /// l'utilisateur swipe ailleurs avant la fin du await.
  int _resolveToken = 0;

  List<_StoryMediaItem> _mediasOf(int eventIdx) {
    final e = widget.events[eventIdx];
    return _mediasCache.putIfAbsent(e.id, () => mediasOfEvent(e));
  }

  int _mediaCountOf(int eventIdx) {
    final medias = _mediasOf(eventIdx);
    // Au moins 1 segment, meme pour un event sans media (placeholder couleur).
    return medias.isEmpty ? 1 : medias.length;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _progress = AnimationController(vsync: this, duration: _photoDuration)
      ..addStatusListener(_onProgressStatus);
    _startStory(_current, mediaIdx: 0);
  }

  @override
  void dispose() {
    _resolveToken++; // invalide tout resolve en cours
    _pageCtrl.dispose();
    _progress.removeStatusListener(_onProgressStatus);
    _progress.dispose();
    // Libere tous les VideoPlayerController du cache : on quitte le viewer.
    StoryVideoCache.disposeAll();
    super.dispose();
  }

  /// Demarre la story a [index] sur le media [mediaIdx] : reset progress avec
  /// duree photo par defaut puis, si le media est une video, resout la vraie
  /// duree en background. Pre-charge aussi les videos voisines (event courant
  /// + voisins) pour que le swipe ne montre pas de placeholder.
  void _startStory(int index, {required int mediaIdx}) {
    _currentMediaIdx = mediaIdx;
    final medias = _mediasOf(index);
    _progress
      ..duration = _photoDuration
      ..reset()
      ..forward();

    if (medias.isNotEmpty) {
      final clampedIdx = mediaIdx.clamp(0, medias.length - 1);
      final m = medias[clampedIdx];
      if (m.isVideo) _resolveVideoDuration(m.url, index, clampedIdx);
    }
    _warmCacheAround(index);
  }

  /// Garde une fenetre de controllers actifs en cache (toutes les videos de
  /// l'event courant + 1ere video des events voisins). La premiere lecture
  /// d'une video se fait pendant que l'utilisateur regarde encore le media
  /// precedent -> bascule instantanee.
  void _warmCacheAround(int index) {
    final keep = <String>{};
    // Toutes les videos de l'event courant (utilisateur va y naviguer).
    for (final m in _mediasOf(index)) {
      if (m.isVideo) {
        keep.add(m.url);
        StoryVideoCache.preload(m.url);
      }
    }
    // 1ere video des events voisins pour un swipe horizontal fluide.
    for (final offset in [-1, 1]) {
      final i = index + offset;
      if (i < 0 || i >= widget.events.length) continue;
      final medias = _mediasOf(i);
      for (final m in medias) {
        if (m.isVideo) {
          keep.add(m.url);
          StoryVideoCache.preload(m.url);
          break;
        }
      }
    }
    StoryVideoCache.keepOnly(keep);
  }

  /// Lit la duree de la video via le cache partage (l'init y est deja fait
  /// ou en cours), puis ajuste la progress bar. Cap a [_maxVideoDuration].
  Future<void> _resolveVideoDuration(
    String url,
    int forEventIdx,
    int forMediaIdx,
  ) async {
    final token = ++_resolveToken;

    if (_videoDurations.containsKey(url)) {
      _applyDuration(_videoDurations[url]!, token, forEventIdx, forMediaIdx);
      return;
    }

    try {
      final ctrl = await StoryVideoCache.take(url);
      var d = ctrl.value.duration;
      if (d <= Duration.zero) d = _photoDuration;
      if (d > _maxVideoDuration) d = _maxVideoDuration;
      _videoDurations[url] = d;
      _applyDuration(d, token, forEventIdx, forMediaIdx);
    } catch (e) {
      debugPrint('[StoryViewer] resolve duration failed: $e');
    }
  }

  /// Applique la duree resolue SI l'utilisateur n'a pas swipe ailleurs
  /// entre-temps et que la story+media courants sont toujours ceux vises.
  void _applyDuration(
    Duration d,
    int token,
    int forEventIdx,
    int forMediaIdx,
  ) {
    if (!mounted) return;
    if (token != _resolveToken) return;
    if (forEventIdx != _current) return;
    if (forMediaIdx != _currentMediaIdx) return;
    if (_progress.status == AnimationStatus.completed) return;

    final progressedFraction = _progress.value;
    _progress.stop();
    _progress.duration = d;
    if (!_isPaused) {
      _progress.forward(from: progressedFraction);
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goNext();
  }

  /// Avance au media suivant : interne a l'event si possible, sinon event
  /// suivant. Au dernier media du dernier event, ferme le viewer.
  void _goNext() {
    final mediaCount = _mediaCountOf(_current);
    if (_currentMediaIdx < mediaCount - 1) {
      setState(() => _currentMediaIdx++);
      _startStory(_current, mediaIdx: _currentMediaIdx);
      return;
    }
    if (_current < widget.events.length - 1) {
      _pageCtrl.animateToPage(
        _current + 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Recule au media precedent : interne a l'event si possible, sinon event
  /// precedent au DERNIER media (UX Snap). Sur le 1er media du 1er event,
  /// relance simplement la progression.
  void _goPrev() {
    if (_currentMediaIdx > 0) {
      setState(() => _currentMediaIdx--);
      _startStory(_current, mediaIdx: _currentMediaIdx);
      return;
    }
    if (_current > 0) {
      final prevLastMedia = _mediaCountOf(_current - 1) - 1;
      _pendingMediaIdxOnArrival = prevLastMedia;
      _pageCtrl.animateToPage(
        _current - 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Premier media du premier event : on relance la progression.
      _startStory(_current, mediaIdx: 0);
    }
  }

  void _onPageChanged(int i) {
    final arrivalIdx = _pendingMediaIdxOnArrival ?? 0;
    _pendingMediaIdxOnArrival = null;
    setState(() {
      _current = i;
      _currentMediaIdx = arrivalIdx;
    });
    _isPaused = false;
    // Reset le flag chat pause au changement de story : la pill "Discuter"
    // ou le focus TextField precedent ne doit pas bloquer la nouvelle bulle.
    if (ref.read(chatInputFocusedProvider)) {
      ref.read(chatInputFocusedProvider.notifier).state = false;
    }
    _startStory(i, mediaIdx: arrivalIdx);
  }

  void _handleTap(TapUpDetails details, double width) {
    final dx = details.localPosition.dx;
    if (dx < width / 3) {
      _goPrev();
    } else {
      _goNext();
    }
  }

  void _pause() {
    if (_isPaused) return;
    setState(() => _isPaused = true);
    _progress.stop();
  }

  void _resume() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Quand l'user focus le TextField de chat -> pause auto-advance + video.
    // Au blur -> reprend automatiquement.
    ref.listen<bool>(chatInputFocusedProvider, (prev, next) {
      if (next) {
        _pause();
      } else {
        _resume();
      }
    });
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // PageView plein ecran swipable. La GestureDetector wrap permet
          // les tap zones et le long-press pour pause sans casser le swipe
          // horizontal natif du PageView.
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                // deferToChild : les boutons inner du detail (like, share)
                // gardent leur tap. Si rien d'inner ne consomme, on prend.
                behavior: HitTestBehavior.deferToChild,
                onTapUp: (d) => _handleTap(d, constraints.maxWidth),
                onLongPressStart: (_) => _pause(),
                onLongPressEnd: (_) => _resume(),
                onLongPressCancel: _resume,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.events.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, index) {
                    // Seul l'event visible utilise le mediaIdx courant ; les
                    // voisins (caches par PageView) restent au 1er media pour
                    // la previsualisation.
                    final mediaIdx =
                        index == _current ? _currentMediaIdx : 0;
                    return ReportedEventDetailSheet(
                      event: widget.events[index],
                      mediaIndex: mediaIdx,
                      initialScrollToChat: index == widget.initialIndex &&
                          widget.initialScrollToChat,
                    );
                  },
                ),
              );
            },
          ),

          // Progress bars segmentees en haut, fade out quand long-press
          // (style Snap : on cache l'UI pour profiter du media).
          Positioned(
            top: topInset + 6,
            left: 14,
            right: 14,
            child: AnimatedOpacity(
              opacity: _isPaused ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => _ProgressBars(
                  // Barres = medias de l'event COURANT (style Snap), pas la
                  // totalite des events de la stripe.
                  count: _mediaCountOf(_current),
                  currentIndex: _currentMediaIdx,
                  currentValue: _progress.value,
                ),
              ),
            ),
          ),

          // Bouton close style glass (spec Neon : 30x30 rond, bg noir + blur)
          Positioned(
            top: topInset + 14,
            right: 12,
            child: AnimatedOpacity(
              opacity: _isPaused ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
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

/// Barres de progression segmentees facon Insta/Snap stories.
/// - segments deja vus : pleins
/// - segment courant : se remplit en temps reel
/// - segments a venir : vide
class _ProgressBars extends StatelessWidget {
  final int count;
  final int currentIndex;
  final double currentValue;

  const _ProgressBars({
    required this.count,
    required this.currentIndex,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final double value;
        if (i < currentIndex) {
          value = 1.0;
        } else if (i == currentIndex) {
          value = currentValue.clamp(0.0, 1.0);
        } else {
          value = 0.0;
        }
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
