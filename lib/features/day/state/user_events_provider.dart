import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

const _storageKey = 'user_events';

final userEventsProvider =
    StateNotifierProvider<UserEventsNotifier, List<UserEvent>>((ref) {
  return UserEventsNotifier();
});

class UserEventsNotifier extends StateNotifier<List<UserEvent>> {
  final UserEventSupabaseService _supabase;

  UserEventsNotifier({UserEventSupabaseService? supabase})
      : _supabase = supabase ?? UserEventSupabaseService(),
        super([]) {
    _init();
  }

  Future<void> _init() async {
    // Charger le cache local immédiatement
    await _loadLocal();

    // Puis synchroniser avec Supabase
    await _syncFromSupabase();
  }

  // ─────────────────────────────────────────
  // Cache local (SharedPreferences) — fallback
  // ─────────────────────────────────────────

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded
        .map((e) => UserEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // ─────────────────────────────────────────
  // Supabase — source de vérité
  // ─────────────────────────────────────────

  /// Récupère les événements depuis Supabase, supprime les expirés,
  /// et met à jour le state + cache local.
  Future<void> _syncFromSupabase() async {
    try {
      // 1. Supprimer les événements passés côté serveur
      await _supabase.deleteExpiredEvents();

      // 2. Récupérer les événements restants
      final events = await _supabase.fetchEvents();
      state = events;
      await _persistLocal();
    } catch (_) {
      // En cas d'erreur réseau, on garde le cache local
    }
  }

  /// Ajoute un événement : upload photo → insert Supabase → update state.
  /// Si [establishmentId] est fourni, insère aussi dans establishment_events
  /// pour déclencher les notifications aux likers du lieu.
  Future<void> addEvent(
    UserEvent event, {
    String? establishmentId,
  }) async {
    // 1. Upload de la photo si présente
    String? photoUrl;
    if (event.photoPath != null && event.photoPath!.isNotEmpty) {
      try {
        photoUrl = await _supabase.uploadPhoto(event.photoPath!);
        debugPrint('[UserEvents] photo upload OK: $photoUrl');
      } catch (e) {
        debugPrint('[UserEvents] photo upload FAILED: $e');
      }
    }

    // 2. Mettre à jour l'event avec l'URL de la photo
    final eventWithUrl = event.copyWith(photoUrl: photoUrl);

    // 3. Insérer dans Supabase (+ establishment_events si lieu curate)
    try {
      await _supabase.insertEvent(
        eventWithUrl,
        establishmentId: establishmentId,
      );
      debugPrint('[UserEvents] insert Supabase OK');
    } catch (e) {
      debugPrint('[UserEvents] insert Supabase FAILED: $e');
    }

    // 4. Mettre à jour le state et le cache local
    state = [eventWithUrl, ...state];
    await _persistLocal();
  }

  /// Supprime un événement de Supabase et du state.
  Future<void> removeEvent(String id) async {
    try {
      await _supabase.deleteEvent(id);
    } catch (_) {
      // Suppression distante échouée : on supprime quand même localement
    }

    state = state.where((e) => e.id != id).toList();
    await _persistLocal();
  }

  /// Force une re-synchronisation depuis Supabase.
  Future<void> refresh() async {
    await _syncFromSupabase();
  }
}
