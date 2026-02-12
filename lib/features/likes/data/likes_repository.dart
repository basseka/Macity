import 'package:shared_preferences/shared_preferences.dart';

class LikesRepository {
  static const _key = 'liked_items';

  Future<Set<String>> getLikedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<void> toggleLike(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();

    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }

    await prefs.setStringList(_key, set.toList());
  }

  Future<bool> isLiked(String id) async {
    final items = await getLikedItems();
    return items.contains(id);
  }
}
