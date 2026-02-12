import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/database/tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAll() => select(categories).get();

  Future<Category?> findByNom(String nom) {
    return (select(categories)..where((c) => c.nom.equals(nom)))
        .getSingleOrNull();
  }

  Future<Category?> findByNafCode(String nafCode) async {
    final all = await getAll();
    for (final cat in all) {
      final codes = cat.nafCodes.split(',').map((c) => c.trim());
      if (codes.contains(nafCode)) return cat;
    }
    return null;
  }

  Future<void> insertAll(List<CategoriesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(categories, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> deleteAll() {
    return delete(categories).go();
  }
}
