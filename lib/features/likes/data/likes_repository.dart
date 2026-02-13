import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/likes/data/likes_supabase_service.dart';

class LikesRepository {
  static const _key = 'liked_items';
  final LikesSupabaseService _supabase;

  LikesRepository({LikesSupabaseService? supabase})
      : _supabase = supabase ?? LikesSupabaseService();

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
      // Sync Supabase (fire & forget)
      _supabase.removeLike(id).catchError(
        (e) => debugPrint('[Likes] removeLike failed: $e'),
      );
    } else {
      set.add(id);
      _supabase.addLike(id).catchError(
        (e) => debugPrint('[Likes] addLike failed: $e'),
      );
    }

    await prefs.setStringList(_key, set.toList());
  }

  Future<bool> isLiked(String id) async {
    final items = await getLikedItems();
    return items.contains(id);
  }

  /// Synchronise les likes locaux vers Supabase (appeler au demarrage).
  Future<void> syncToSupabase() async {
    try {
      final localIds = await getLikedItems();
      if (localIds.isNotEmpty) {
        await _supabase.syncLocalLikes(localIds);
      }
    } catch (e) {
      debugPrint('[Likes] initial sync failed: $e');
    }
  }
}
