import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracker de vues reelles pour les reported_events.
///
/// Flow :
///   1. UI detecte visibilite >= 50% pendant >= 1s -> onSeen(id)
///   2. Dedup locale : 1 vue / event / device / 24h via SharedPreferences
///   3. Batch : accumule les nouveaux ids, flush toutes les 5s via RPC
///   4. RPC `increment_reported_event_views(p_ids uuid[])` increment atomique
class ViewTracker {
  ViewTracker._();
  static final ViewTracker instance = ViewTracker._();

  static const _dedupKey = 'rep_views_dedup';
  static const _dedupWindowMs = 24 * 3600 * 1000;
  static const _flushDelay = Duration(seconds: 5);

  final Set<String> _pending = {};
  Timer? _flushTimer;
  Dio? _dio;

  Dio get _restDio {
    _dio ??= DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
      ..interceptors.add(SupabaseInterceptor());
    return _dio!;
  }

  /// Signale qu'une affiche a ete vue suffisamment. Dedup cote client.
  Future<void> onSeen(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Purge + lecture des entrees de dedup.
    final raw = prefs.getStringList(_dedupKey) ?? const <String>[];
    final fresh = <String>[];
    bool alreadyViewed = false;
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final ts = int.tryParse(parts[1]);
      if (ts == null) continue;
      if (now - ts > _dedupWindowMs) continue; // expire
      fresh.add(entry);
      if (parts[0] == eventId) alreadyViewed = true;
    }

    if (alreadyViewed) return;

    fresh.add('$eventId|$now');
    await prefs.setStringList(_dedupKey, fresh);

    _pending.add(eventId);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDelay, _flush);
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) return;
    final ids = _pending.toList();
    _pending.clear();

    try {
      await _restDio.post(
        'rpc/increment_reported_event_views',
        data: {'p_ids': ids},
        options: Options(
          headers: {'Prefer': 'return=minimal'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[ViewTracker] flush failed for ${ids.length} ids: $e');
      // Best-effort : on ne requeue pas (evite les boucles si l'API est down).
    }
  }
}
