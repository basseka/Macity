import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pulz_app/core/database/tables/commerce_table.dart';
import 'package:pulz_app/core/database/tables/category_table.dart';
import 'package:pulz_app/core/database/tables/ville_table.dart';
import 'package:pulz_app/core/database/daos/commerce_dao.dart';
import 'package:pulz_app/core/database/daos/category_dao.dart';
import 'package:pulz_app/core/database/daos/ville_dao.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Commerces, Categories, Villes],
  daos: [CommerceDao, CategoryDao, VilleDao],
)
class AppDatabase extends _$AppDatabase {
  /// Singleton instance.
  static AppDatabase? _instance;

  factory AppDatabase() => _instance ??= AppDatabase._internal();

  AppDatabase._internal() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 4) {
          await m.deleteTable('commerces');
          await m.deleteTable('categories');
          await m.deleteTable('villes');
          await m.createAll();
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'commerces_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
