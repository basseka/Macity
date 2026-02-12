import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/database/seed/seed_categories.dart';
import 'package:pulz_app/core/database/seed/seed_villes.dart';
import 'package:pulz_app/core/database/seed/seed_commerces.dart';

class DatabaseSeeder {
  final AppDatabase _db;

  DatabaseSeeder(this._db);

  Future<void> seedIfEmpty() async {
    final categoryCount = (await _db.categoryDao.getAll()).length;
    if (categoryCount > 0) return;

    await _seedCategories();
    await _seedVilles();
    await _seedCommerces();
  }

  Future<void> _seedCategories() async {
    await _db.categoryDao.insertAll(SeedCategories.all);
  }

  Future<void> _seedVilles() async {
    await _db.villeDao.insertAll(SeedVilles.all);
  }

  Future<void> _seedCommerces() async {
    await _db.commerceDao.insertAll(SeedCommerces.all);
  }

  Future<void> reseed() async {
    await _db.commerceDao.deleteAll();
    await _db.categoryDao.deleteAll();
    await _db.villeDao.deleteAll();
    await seedIfEmpty();
  }
}
