import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/reviews/data/commerce_review_service.dart';
import 'package:pulz_app/features/reviews/domain/models/commerce_review.dart';

/// Cache global "kind:id" -> summary (ou null si chargé sans avis).
/// Les cartes pushent leur (kind, id) via [request] et lisent leur entree
/// via [select] pour ne pas rebuild a chaque load voisin.
class CommerceSummariesNotifier
    extends StateNotifier<Map<String, CommerceReviewSummary?>> {
  CommerceSummariesNotifier() : super(const {});

  final _service = CommerceReviewService();
  final Map<String, Set<int>> _pending = {};
  Timer? _flushTimer;

  /// Demande la summary pour ce commerce. Idempotent : si deja chargee ou
  /// en vol, no-op. Sinon ajoute au batch et flush dans 50ms.
  void request(String kind, int id) {
    final key = '$kind:$id';
    if (state.containsKey(key)) return;
    _pending.putIfAbsent(kind, () => {}).add(id);
    // Marque comme in-flight pour ne pas re-demander pendant le wait.
    state = {...state, key: null};
    _flushTimer ??= Timer(const Duration(milliseconds: 50), _flush);
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final batches = Map.of(_pending);
    _pending.clear();
    for (final entry in batches.entries) {
      final kind = entry.key;
      final ids = entry.value.toList();
      try {
        final loaded = await _service.summariesBatch(
          targetKind: kind,
          targetIds: ids,
        );
        // Merge : ids sans avis restent null (deja en state via request).
        state = {...state, ...loaded};
      } catch (e) {
        debugPrint('[CommerceSummaries] batch failed for $kind: $e');
      }
    }
  }

  /// Force le rechargement d'une summary (apres submit/delete d'un avis).
  Future<void> refresh(String kind, int id) async {
    final key = '$kind:$id';
    final loaded = await _service.summariesBatch(
      targetKind: kind,
      targetIds: [id],
    );
    state = {...state, key: loaded[key]};
  }
}

final commerceSummariesProvider = StateNotifierProvider<
    CommerceSummariesNotifier, Map<String, CommerceReviewSummary?>>(
  (ref) => CommerceSummariesNotifier(),
);
