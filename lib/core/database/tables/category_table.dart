import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get nom => text()();
  TextColumn get emoji => text()();
  TextColumn get nafCodes => text().withDefault(const Constant(''))();
  TextColumn get osmTags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {nom};
}
