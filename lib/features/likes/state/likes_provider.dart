import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';

class LikesNotifier extends StateNotifier<Set<String>> {
  final LikesRepository _repository;

  LikesNotifier(this._repository) : super({}) {
    _load();
  }

  Future<void> _load() async {
    state = await _repository.getLikedItems();
  }

  Future<void> toggle(String id) async {
    await _repository.toggleLike(id);
    state = await _repository.getLikedItems();
  }

  bool isLiked(String id) => state.contains(id);
}

final likesProvider = StateNotifierProvider<LikesNotifier, Set<String>>(
  (ref) => LikesNotifier(LikesRepository()),
);
