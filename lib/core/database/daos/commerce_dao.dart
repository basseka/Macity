import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/database/tables/commerce_table.dart';

part 'commerce_dao.g.dart';

@DriftAccessor(tables: [Commerces])
class CommerceDao extends DatabaseAccessor<AppDatabase>
    with _$CommerceDaoMixin {
  CommerceDao(super.db);

  Future<List<Commerce>> getAll() => select(commerces).get();

  Future<List<Commerce>> findByVille(String ville) {
    return (select(commerces)..where((c) => c.ville.equals(ville))).get();
  }

  Future<List<Commerce>> findNearby(
    double latMin,
    double latMax,
    double lonMin,
    double lonMax,
  ) {
    return (select(commerces)
          ..where((c) =>
              c.latitude.isBetweenValues(latMin, latMax) &
              c.longitude.isBetweenValues(lonMin, lonMax),))
        .get();
  }

  Future<List<Commerce>> searchInVille(String ville, String query) {
    final pattern = '%$query%';
    return (select(commerces)
          ..where((c) =>
              c.ville.equals(ville) &
              (c.nom.like(pattern) | c.categorie.like(pattern)),))
        .get();
  }

  Future<Commerce?> findBySiret(String siret) {
    return (select(commerces)..where((c) => c.siret.equals(siret)))
        .getSingleOrNull();
  }

  Future<List<Commerce>> findUnsynced() {
    return (select(commerces)..where((c) => c.synced.equals(false))).get();
  }

  Future<int?> getMaxLastUpdated() async {
    final query = selectOnly(commerces)
      ..addColumns([commerces.lastUpdated.max()]);
    final result = await query.getSingleOrNull();
    return result?.read(commerces.lastUpdated.max());
  }

  Future<int> countByVille(String ville) async {
    final count = commerces.id.count();
    final query = selectOnly(commerces)
      ..addColumns([count])
      ..where(commerces.ville.equals(ville));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> insertCommerce(CommercesCompanion entry) {
    return into(commerces).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertAll(List<CommercesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(commerces, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<bool> updateCommerce(Commerce entry) {
    return update(commerces).replace(entry);
  }

  Future<int> deleteAll() {
    return delete(commerces).go();
  }
}
