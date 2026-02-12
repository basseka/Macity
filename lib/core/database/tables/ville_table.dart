import 'package:drift/drift.dart';

class Villes extends Table {
  TextColumn get nom => text()();
  TextColumn get codePostal => text()();
  TextColumn get codeInsee => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get lastSireneSync => integer().withDefault(const Constant(0))();
  IntColumn get lastOsmSync => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {nom};
}
