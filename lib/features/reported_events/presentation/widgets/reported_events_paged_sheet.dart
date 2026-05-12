import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/reported_event_detail_sheet.dart';
import 'package:pulz_app/features/reported_events/state/chat_provider.dart';
import 'package:video_player/video_player.dart';

/// Viewer plein ecran style Snapchat / Instagram stories.
///
/// Comportement :
///  - progress bars segmentees en haut (une par bulle, remplissage temps reel)
///  - auto-advance 5s par story (puis pop a la derniere)
///  - tap zone gauche (1/3) → bulle precedente
///  - tap zone droite (2/3) → bulle suivante
///  - long-press n'importe ou → pause progression + video
///  - swipe horizontal libre via PageView (override fluide de l'auto-advance)
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
  bool _isPaused = false;

  /// Cache des durees video resolues (cle = url) pour eviter de re-initialiser
  /// un VideoPlayerController en cas de re-visite.
  final Map<String, Duration> _videoDurations = {};

  /// Token monotone pour invalider une resolution de duree en cours quand
  /// l'utilisateur swipe ailleurs avant la fin du await.
  int _resolveToken = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _progress = AnimationController(vsync: this, duration: _photoDuration)
      ..addStatusListener(_onProgressStatus);
    _startStory(_current);
  }

  @override
  void dispose() {
    _resolveToken++; // invalide tout resolve en cours
    _pageCtrl.dispose();
    _progress.removeStatusListener(_onProgressStatus);
    _progress.dispose();
    super.dispose();
  }

  /// Demarre la story a [index] : reset progress avec duree par defaut puis
  /// resout la vraie duree video en background si applicable.
  void _startStory(int index) {
    final event = widget.events[index];
    _progress
      ..duration = _photoDuration
      ..reset()
      ..forward();

    if (event.videos.isNotEmpty) {
      _resolveVideoDuration(event.videos.first, index);
    }
  }

  /// Initialise un VideoPlayerController juste pour lire les metadonnees
  /// (durée), puis ajuste la progress bar courante. Cap a [_maxVideoDuration].
  Future<void> _resolveVideoDuration(String url, int forIndex) async {
    final token = ++_resolveToken;

    // Cache hit → applique directement
    if (_videoDurations.containsKey(url)) {
      _applyDuration(_videoDurations[url]!, token, forIndex);
      return;
    }

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await ctrl.initialize();
      var d = ctrl.value.duration;
      if (d <= Duration.zero) d = _photoDuration;
      if (d > _maxVideoDuration) d = _maxVideoDuration;
      _videoDurations[url] = d;
      _applyDuration(d, token, forIndex);
    } catch (e) {
      debugPrint('[StoryViewer] resolve duration failed: $e');
    } finally {
      await ctrl.dispose();
    }
  }

  /// Applique la duree resolue SI l'utilisateur n'a pas swipe ailleurs
  /// entre-temps et que la story courante est toujours [forIndex].
  void _applyDuration(Duration d, int token, int forIndex) {
    if (!mounted) return;
    if (token != _resolveToken) return;
    if (forIndex != _current) return;
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

  void _goNext() {
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

  void _goPrev() {
    if (_current > 0) {
      _pageCtrl.animateToPage(
        _current - 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Premiere story : on relance la progression au lieu de pop.
      _startStory(_current);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _isPaused = false;
    // Reset le flag chat pause au changement de story : la pill "Discuter"
    // ou le focus TextField precedent ne doit pas bloquer la nouvelle bulle.
    if (ref.read(chatInputFocusedProvider)) {
      ref.read(chatInputFocusedProvider.notifier).state = false;
    }
    _startStory(i);
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
                  itemBuilder: (_, index) => ReportedEventDetailSheet(
                    event: widget.events[index],
                    initialScrollToChat: index == widget.initialIndex &&
                        widget.initialScrollToChat,
                  ),
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
                  count: widget.events.length,
                  currentIndex: _current,
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
