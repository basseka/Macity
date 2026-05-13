import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/engagement/data/event_engagement_service.dart';
import 'package:pulz_app/features/engagement/domain/models/device_pseudonym.dart';
import 'package:pulz_app/features/engagement/domain/models/event_comment.dart';
import 'package:pulz_app/features/engagement/domain/models/event_engagement_totals.dart';

/// Clé composite pour les caches : `<source>:<identifiant>`.
String engagementKey(String source, String identifiant) =>
    '$source:$identifiant';

// =============================================================================
// 1. Totals (likes/shares/comments) — batch loader
// =============================================================================

class EngagementTotalsState {
  final Map<String, EventEngagementTotals?> totals; // null = chargé mais pas boosté
  final Map<String, bool> userLiked;                // true si le device a liké
  const EngagementTotalsState({this.totals = const {}, this.userLiked = const {}});

  EngagementTotalsState copyWith({
    Map<String, EventEngagementTotals?>? totals,
    Map<String, bool>? userLiked,
  }) =>
      EngagementTotalsState(
        totals: totals ?? this.totals,
        userLiked: userLiked ?? this.userLiked,
      );
}

class EngagementTotalsNotifier extends StateNotifier<EngagementTotalsState> {
  EngagementTotalsNotifier(this._service) : super(const EngagementTotalsState());

  final EventEngagementService _service;
  final Map<String, Set<String>> _pendingTotals = {}; // source -> ids
  final Set<String> _inFlight = {};                   // keys en cours de fetch
  final Set<String> _loaded = {};                     // keys dont le fetch a abouti (résultat ou empty)
  Timer? _flushTimer;

  /// Demande les totaux pour un event. Batch toutes les 50ms.
  /// Re-fetch automatiquement si la key n'a pas encore été chargée OU si
  /// elle a été chargée vide précédemment (cas migration de schema).
  void request(String source, String identifiant) {
    final key = engagementKey(source, identifiant);
    if (_loaded.contains(key)) return;
    if (_inFlight.contains(key)) return;
    _inFlight.add(key);
    _pendingTotals.putIfAbsent(source, () => {}).add(identifiant);
    _flushTimer ??= Timer(const Duration(milliseconds: 50), _flush);
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final batches = Map.of(_pendingTotals);
    _pendingTotals.clear();
    for (final entry in batches.entries) {
      final source = entry.key;
      final ids = entry.value.toList();
      try {
        final loaded = await _service.getTotalsBatch(
          eventSource: source,
          eventIdentifiants: ids,
        );
        // Met à jour les rows trouvées + marque toutes les keys demandées comme "loaded"
        final updates = <String, EventEngagementTotals?>{};
        for (final id in ids) {
          final key = engagementKey(source, id);
          updates[key] = loaded[key]; // null si pas dans le résultat
          _inFlight.remove(key);
          _loaded.add(key);
        }
        state = state.copyWith(totals: {...state.totals, ...updates});
      } catch (e) {
        debugPrint('[Engagement] flush totals failed: $e');
        for (final id in ids) {
          _inFlight.remove(engagementKey(source, id));
        }
      }
    }
  }

  /// Force le rechargement après une mutation locale (like/comment).
  Future<void> refresh(String source, String identifiant) async {
    final key = engagementKey(source, identifiant);
    final t = await _service.getTotals(
      eventSource: source,
      eventIdentifiant: identifiant,
    );
    state = state.copyWith(totals: {...state.totals, key: t});
  }

  /// Charge le statut "j'ai liké ?" pour le device courant.
  Future<bool> loadUserLiked(String source, String identifiant) async {
    final key = engagementKey(source, identifiant);
    if (state.userLiked.containsKey(key)) return state.userLiked[key]!;
    final deviceUuid = await UserIdentityService.getUserId();
    final liked = await _service.hasUserLiked(
      eventSource: source,
      eventIdentifiant: identifiant,
      deviceUuid: deviceUuid,
    );
    state = state.copyWith(userLiked: {...state.userLiked, key: liked});
    return liked;
  }

  /// Toggle like (optimistic update + rollback en cas d'échec).
  Future<void> toggleLike(String source, String identifiant) async {
    final key = engagementKey(source, identifiant);
    final deviceUuid = await UserIdentityService.getUserId();
    final wasLiked = state.userLiked[key] ?? false;
    final current = state.totals[key];

    // Construit le prochain totals (synthetique si l'event n'a pas de row
    // d'engagement — sinon le compteur ne ticquerait jamais cote UI).
    final base = current ?? EventEngagementTotals.empty(source, identifiant);
    final next = EventEngagementTotals(
      eventSource: base.eventSource,
      eventIdentifiant: base.eventIdentifiant,
      likesCount: (base.likesCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 30),
      sharesCount: base.sharesCount,
      commentsCount: base.commentsCount,
      boostType: base.boostType,
      seededAt: base.seededAt,
    );

    // Optimistic update
    state = state.copyWith(
      userLiked: {...state.userLiked, key: !wasLiked},
      totals: {...state.totals, key: next},
    );

    try {
      if (wasLiked) {
        await _service.removeLike(
          eventSource: source,
          eventIdentifiant: identifiant,
          deviceUuid: deviceUuid,
        );
      } else {
        await _service.addLike(
          eventSource: source,
          eventIdentifiant: identifiant,
          deviceUuid: deviceUuid,
        );
      }
    } catch (e) {
      debugPrint('[Engagement] toggleLike failed: $e — rolling back');
      // Rollback : on remet l'etat tel qu'il etait. Si current etait null
      // on retire la cle synthetique creee par l'update optimiste.
      final rolledTotals = {...state.totals};
      if (current == null) {
        rolledTotals.remove(key);
      } else {
        rolledTotals[key] = current;
      }
      state = state.copyWith(
        userLiked: {...state.userLiked, key: wasLiked},
        totals: rolledTotals,
      );
      rethrow;
    }
  }

  /// Bump le compteur shares (côté visuel) et POST en DB.
  Future<void> recordShare(String source, String identifiant) async {
    final key = engagementKey(source, identifiant);
    final deviceUuid = await UserIdentityService.getUserId();
    final current = state.totals[key];
    // Construit un totals synthetique si l'event n'a pas encore de row,
    // pour que le compteur de partages ticque cote UI.
    final base = current ?? EventEngagementTotals.empty(source, identifiant);
    state = state.copyWith(totals: {
      ...state.totals,
      key: EventEngagementTotals(
        eventSource: base.eventSource,
        eventIdentifiant: base.eventIdentifiant,
        likesCount: base.likesCount,
        sharesCount: base.sharesCount + 1,
        commentsCount: base.commentsCount,
        boostType: base.boostType,
        seededAt: base.seededAt,
      ),
    },);
    try {
      await _service.recordShare(
        eventSource: source,
        eventIdentifiant: identifiant,
        deviceUuid: deviceUuid,
      );
    } catch (e) {
      debugPrint('[Engagement] recordShare failed: $e');
    }
  }
}

final engagementServiceProvider = Provider<EventEngagementService>(
  (ref) => EventEngagementService(),
);

final engagementTotalsProvider =
    StateNotifierProvider<EngagementTotalsNotifier, EngagementTotalsState>(
  (ref) => EngagementTotalsNotifier(ref.read(engagementServiceProvider)),
);

// =============================================================================
// 2. Comments (lecture sheet) — FutureProvider.family
// =============================================================================

final eventCommentsProvider = FutureProvider.family
    .autoDispose<List<EventComment>, ({String source, String identifiant})>(
  (ref, key) async {
    final service = ref.read(engagementServiceProvider);
    return service.listComments(
      eventSource: key.source,
      eventIdentifiant: key.identifiant,
    );
  },
);

// =============================================================================
// 3. Pseudo du device courant (chargé une fois, mis en cache)
// =============================================================================

final devicePseudonymProvider = FutureProvider<DevicePseudonym?>((ref) async {
  final service = ref.read(engagementServiceProvider);
  final deviceUuid = await UserIdentityService.getUserId();
  return service.getOrAssignPseudonym(deviceUuid);
});
