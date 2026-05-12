import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Cache partage de [VideoPlayerController] pour le viewer story (Insta-like).
///
/// Le paged_sheet pre-charge la video de la story suivante pendant que
/// l'utilisateur regarde la courante : init reseau + decoder warm-up se font
/// en background, l'arrivee sur la story suivante est instantanee.
///
/// Strategie d'eviction : on garde une fenetre de 3 (prev / curr / next) pour
/// snapper en avant ET en arriere. Au-dela, on dispose pour liberer le
/// decodeur natif (limites materielles : iOS ~ 4-6 decoders simultanes max).
class StoryVideoCache {
  static final Map<String, _CacheEntry> _entries = {};

  /// Demarre l'init en background si pas deja en cours. Idempotent.
  static void preload(String url) {
    if (url.isEmpty) return;
    if (_entries.containsKey(url)) return;
    _entries[url] = _CacheEntry._start(url);
  }

  /// Recupere (ou attend) le controller initialise pour [url]. Lance l'init
  /// si l'URL n'est pas encore dans le cache.
  static Future<VideoPlayerController> take(String url) {
    var entry = _entries[url];
    entry ??= _entries[url] = _CacheEntry._start(url);
    return entry.future;
  }

  /// Evict tous les entries dont l'URL n'est pas dans [keep]. Le controller
  /// est dispose proprement.
  static void keepOnly(Set<String> keep) {
    final toRemove = _entries.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toRemove) {
      _entries.remove(k)?.dispose();
    }
  }

  /// Detruit tout le cache (appele quand le viewer story se ferme).
  static void disposeAll() {
    for (final e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
  }
}

class _CacheEntry {
  final Future<VideoPlayerController> future;
  VideoPlayerController? _ctrl;
  bool _disposed = false;

  _CacheEntry._(this.future);

  factory _CacheEntry._start(String url) {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    final future = ctrl.initialize().then((_) {
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      return ctrl;
    }).catchError((e) {
      debugPrint('[StoryVideoCache] init failed for $url: $e');
      // Re-throw pour que les awaiters puissent retomber sur le placeholder
      // photo. Le controller reste reference pour dispose plus tard.
      throw e;
    });
    final entry = _CacheEntry._(future);
    entry._ctrl = ctrl;
    return entry;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final c = _ctrl;
    if (c == null) return;
    // Si l'init est encore en cours, on dispose apres pour eviter une race.
    future.whenComplete(() {
      try {
        c.pause();
      } catch (_) {}
      c.dispose();
    }).ignore();
  }
}
