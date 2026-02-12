import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';

class CommerceAddNotifier extends StateNotifier<AsyncValue<void>> {
  final CommerceRepository _repository;

  CommerceAddNotifier(this._repository) : super(const AsyncData(null));

  Future<bool> addCommerce({
    required String nom,
    required String adresse,
    required String ville,
    required String codePostal,
    required String categorie,
    required double latitude,
    required double longitude,
    String? horaires,
    String? telephone,
  }) async {
    state = const AsyncLoading();

    final entry = CommercesCompanion(
      nom: Value(nom),
      adresse: Value(adresse),
      ville: Value(ville),
      codePostal: Value(codePostal),
      categorie: Value(categorie),
      latitude: Value(latitude),
      longitude: Value(longitude),
      horaires: Value(horaires ?? ''),
      telephone: Value(telephone ?? ''),
      source: const Value('user'),
      lastUpdated: Value(DateTime.now().millisecondsSinceEpoch),
    );

    final success = await _repository.addCommerce(entry);
    state = const AsyncData(null);
    return success;
  }
}

final commerceAddProvider =
    StateNotifierProvider<CommerceAddNotifier, AsyncValue<void>>(
  (ref) {
    final db = AppDatabase();
    return CommerceAddNotifier(CommerceRepository(db: db));
  },
);
