import 'dart:async';

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
    final entry = _entries[url] = _CacheEntry._start(url);
    // Observe la future pour eviter un "unhandled exception" si le preload
    // echoue sans take() derriere. L'eviction est geree par _CacheEntry._start.
    entry.future.ignore();
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
    late final _CacheEntry entry;
    final future = ctrl
        .initialize()
        // Une init reseau peut rester pendante indefiniment (objet Storage
        // pas encore propage sur le CDN juste apres un upload). On borne
        // pour pouvoir retomber sur la photo puis retenter.
        .timeout(const Duration(seconds: 12))
        .then((_) {
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      return ctrl;
    }).catchError((Object e) {
      debugPrint('[StoryVideoCache] init failed for $url: $e');
      // Auto-eviction : une init echouee ne doit PAS empoisonner le cache.
      // Sans ca, tous les take()/preload() suivants renvoient cette meme
      // future deja rejetee -> la video ne se lance jamais (cas typique
      // d'un signalement tout frais : le CDN ne sert pas encore la video).
      // En retirant l'entree, le prochain take() relance une vraie tentative.
      if (identical(StoryVideoCache._entries[url], entry)) {
        StoryVideoCache._entries.remove(url);
      }
      ctrl.dispose();
      // Re-throw pour que les awaiters retombent sur le placeholder photo.
      throw e;
    });
    entry = _CacheEntry._(future);
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
