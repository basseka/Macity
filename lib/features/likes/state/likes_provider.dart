import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';

class LikesNotifier extends StateNotifier<Set<String>> {
  final LikesRepository _repository;

  LikesNotifier(this._repository) : super({}) {
    _load();
  }

  Future<void> _load() async {
    // Charger les likes locaux immediatement pour un affichage rapide
    state = await _repository.getLikedItems();

    // Sync bidirectionnel avec Supabase (local + remote)
    final merged = await _repository.syncBidirectional();
    state = merged;
  }

  Future<void> toggle(String id, {LikeMetadata? meta}) async {
    final wasLiked = state.contains(id);
    await _repository.toggleLike(id, meta: meta);
    state = await _repository.getLikedItems();
    ActivityService.instance.like(itemId: id, isLike: !wasLiked);
  }

  bool isLiked(String id) => state.contains(id);
}

final likesProvider = StateNotifierProvider<LikesNotifier, Set<String>>(
  (ref) => LikesNotifier(LikesRepository()),
);

/// Provides cached metadata for liked items.
final likesMetaProvider = FutureProvider<Map<String, LikeMetadata>>((ref) async {
  // Re-read whenever likes change
  ref.watch(likesProvider);
  return LikesRepository().getLikedMeta();
});
