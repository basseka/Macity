import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/database/tables/ville_table.dart';

part 'ville_dao.g.dart';

@DriftAccessor(tables: [Villes])
class VilleDao extends DatabaseAccessor<AppDatabase> with _$VilleDaoMixin {
  VilleDao(super.db);

  Future<List<Ville>> getAll() => select(villes).get();

  Future<Ville?> findByNom(String nom) {
    return (select(villes)..where((v) => v.nom.equals(nom)))
        .getSingleOrNull();
  }

  Future<List<Ville>> search(String query) {
    final pattern = '%$query%';
    return (select(villes)..where((v) => v.nom.like(pattern))).get();
  }

  Future<void> insertAll(List<VillesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(villes, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<bool> updateVille(Ville entry) {
    return update(villes).replace(entry);
  }

  Future<int> deleteAll() {
    return delete(villes).go();
  }
}
