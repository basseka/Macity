import 'package:drift/drift.dart';

class Commerces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text()();
  TextColumn get adresse => text().withDefault(const Constant(''))();
  TextColumn get ville => text()();
  TextColumn get codePostal => text().withDefault(const Constant(''))();
  TextColumn get categorie => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get horaires => text().withDefault(const Constant(''))();
  BoolColumn get ouvert => boolean().withDefault(const Constant(true))();
  BoolColumn get independant => boolean().withDefault(const Constant(false))();
  TextColumn get telephone => text().withDefault(const Constant(''))();
  TextColumn get siteWeb => text().withDefault(const Constant(''))();
  TextColumn get lienMaps => text().withDefault(const Constant(''))();
  TextColumn get avis => text().withDefault(const Constant(''))();
  TextColumn get photo => text().withDefault(const Constant(''))();
  TextColumn get siret => text().withDefault(const Constant(''))();
  TextColumn get codeNaf => text().withDefault(const Constant(''))();
  TextColumn get enseigne => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('seed'))();
  IntColumn get lastUpdated => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {siret},
      ];
}
