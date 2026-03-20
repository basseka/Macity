import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/likes/data/likes_supabase_service.dart';

/// Metadata cached alongside a like (title, image, category).
class LikeMetadata {
  final String title;
  final String? imageUrl;
  final String? assetImage;
  final String? category;

  const LikeMetadata({
    required this.title,
    this.imageUrl,
    this.assetImage,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (assetImage != null) 'assetImage': assetImage,
        if (category != null) 'category': category,
      };

  factory LikeMetadata.fromJson(Map<String, dynamic> json) => LikeMetadata(
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        assetImage: json['assetImage'] as String?,
        category: json['category'] as String?,
      );
}

class LikesRepository {
  static const _key = 'liked_items';
  static const _metaKey = 'liked_items_meta';
  final LikesSupabaseService _supabase;

  LikesRepository({LikesSupabaseService? supabase})
      : _supabase = supabase ?? LikesSupabaseService();

  Future<Set<String>> getLikedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<Map<String, LikeMetadata>> getLikedMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, LikeMetadata.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleLike(String id, {LikeMetadata? meta}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();

    if (set.contains(id)) {
      set.remove(id);
      await _removeMeta(prefs, id);
      _supabase.removeLike(id).catchError(
        (e) => debugPrint('[Likes] removeLike failed: $e'),
      );
    } else {
      set.add(id);
      if (meta != null) {
        await _saveMeta(prefs, id, meta);
      }
      _supabase.addLike(id, meta: meta).catchError(
        (e) => debugPrint('[Likes] addLike failed: $e'),
      );
    }

    await prefs.setStringList(_key, set.toList());
  }

  Future<void> _saveMeta(SharedPreferences prefs, String id, LikeMetadata meta) async {
    final raw = prefs.getString(_metaKey);
    final map = raw != null ? (jsonDecode(raw) as Map<String, dynamic>) : <String, dynamic>{};
    map[id] = meta.toJson();
    await prefs.setString(_metaKey, jsonEncode(map));
  }

  Future<void> _removeMeta(SharedPreferences prefs, String id) async {
    final raw = prefs.getString(_metaKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map.remove(id);
    await prefs.setString(_metaKey, jsonEncode(map));
  }

  Future<bool> isLiked(String id) async {
    final items = await getLikedItems();
    return items.contains(id);
  }

  /// Sync bidirectionnel au demarrage : merge local + Supabase.
  /// Retourne l'ensemble fusionne d'IDs.
  Future<Set<String>> syncBidirectional() async {
    try {
      final localIds = await getLikedItems();
      final localMeta = await getLikedMeta();

      final merged = await _supabase.syncBidirectional(
        localIds: localIds,
        localMeta: localMeta,
      );

      // Sauvegarder le resultat fusionne en local
      final prefs = await SharedPreferences.getInstance();
      final mergedIds = merged.keys.toSet();
      await prefs.setStringList(_key, mergedIds.toList());

      // Sauvegarder les metadonnees fusionnees
      final metaMap = <String, dynamic>{};
      for (final entry in merged.entries) {
        if (entry.value.title.isNotEmpty) {
          metaMap[entry.key] = entry.value.toJson();
        }
      }
      await prefs.setString(_metaKey, jsonEncode(metaMap));

      return mergedIds;
    } catch (e) {
      debugPrint('[Likes] bidirectional sync failed: $e');
      // Fallback : retourner les likes locaux
      return getLikedItems();
    }
  }

  /// Ancien sync unidirectionnel (deprecated, utiliser syncBidirectional).
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
