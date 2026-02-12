import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Cache local pour les concerts.
///
/// Stocke les [Event] serialises dans SharedPreferences
/// avec un timestamp pour gerer la fraicheur des donnees.
/// Preserve le champ photoPath (exclu du JSON Freezed).
class ConcertCacheService {
  static const _cacheKey = 'concert_cache_data';
  static const _cacheTimestampKey = 'concert_cache_timestamp';

  /// Duree de validite du cache (6 heures).
  static const cacheDuration = Duration(hours: 6);

  /// Sauvegarde les concerts dans le cache local.
  Future<void> save(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final maps = events.map((e) {
      final map = e.toJson();
      // photoPath est exclu par @JsonKey, on le stocke manuellement
      if (e.photoPath != null) {
        map['_photoPath'] = e.photoPath;
      }
      return map;
    }).toList();
    await prefs.setString(_cacheKey, jsonEncode(maps));
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch,);
  }

  /// Recupere les concerts depuis le cache.
  /// Retourne null si le cache est vide ou expire.
  Future<List<Event>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedAt) > cacheDuration) {
      return null; // Cache expire
    }

    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final photoPath = map.remove('_photoPath') as String?;
        final event = Event.fromJson(map);
        return photoPath != null
            ? event.copyWith(photoPath: photoPath)
            : event;
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Verifie si le cache est encore valide.
  Future<bool> isValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedAt) <= cacheDuration;
  }

  /// Supprime le cache.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
