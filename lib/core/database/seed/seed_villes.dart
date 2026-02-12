import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';

class SeedVilles {
  SeedVilles._();

  static List<VillesCompanion> get all => [
        const VillesCompanion(
          nom: Value('Paris'),
          codePostal: Value('75000'),
          codeInsee: Value('75056'),
          latitude: Value(48.8566),
          longitude: Value(2.3522),
        ),
        const VillesCompanion(
          nom: Value('Lyon'),
          codePostal: Value('69000'),
          codeInsee: Value('69123'),
          latitude: Value(45.7640),
          longitude: Value(4.8357),
        ),
        const VillesCompanion(
          nom: Value('Marseille'),
          codePostal: Value('13000'),
          codeInsee: Value('13055'),
          latitude: Value(43.2965),
          longitude: Value(5.3698),
        ),
        const VillesCompanion(
          nom: Value('Toulouse'),
          codePostal: Value('31000'),
          codeInsee: Value('31555'),
          latitude: Value(43.6047),
          longitude: Value(1.4442),
        ),
        const VillesCompanion(
          nom: Value('Nice'),
          codePostal: Value('06000'),
          codeInsee: Value('06088'),
          latitude: Value(43.7102),
          longitude: Value(7.2620),
        ),
        const VillesCompanion(
          nom: Value('Nantes'),
          codePostal: Value('44000'),
          codeInsee: Value('44109'),
          latitude: Value(47.2184),
          longitude: Value(-1.5536),
        ),
        const VillesCompanion(
          nom: Value('Bordeaux'),
          codePostal: Value('33000'),
          codeInsee: Value('33063'),
          latitude: Value(44.8378),
          longitude: Value(-0.5792),
        ),
        const VillesCompanion(
          nom: Value('Lille'),
          codePostal: Value('59000'),
          codeInsee: Value('59350'),
          latitude: Value(50.6292),
          longitude: Value(3.0573),
        ),
        const VillesCompanion(
          nom: Value('Strasbourg'),
          codePostal: Value('67000'),
          codeInsee: Value('67482'),
          latitude: Value(48.5734),
          longitude: Value(7.7521),
        ),
        const VillesCompanion(
          nom: Value('Montpellier'),
          codePostal: Value('34000'),
          codeInsee: Value('34172'),
          latitude: Value(43.6108),
          longitude: Value(3.8767),
        ),
        const VillesCompanion(
          nom: Value('Rennes'),
          codePostal: Value('35000'),
          codeInsee: Value('35238'),
          latitude: Value(48.1173),
          longitude: Value(-1.6778),
        ),
        const VillesCompanion(
          nom: Value('Grenoble'),
          codePostal: Value('38000'),
          codeInsee: Value('38185'),
          latitude: Value(45.1885),
          longitude: Value(5.7245),
        ),
        const VillesCompanion(
          nom: Value('Rouen'),
          codePostal: Value('76000'),
          codeInsee: Value('76540'),
          latitude: Value(49.4432),
          longitude: Value(1.0999),
        ),
        const VillesCompanion(
          nom: Value('Toulon'),
          codePostal: Value('83000'),
          codeInsee: Value('83137'),
          latitude: Value(43.1242),
          longitude: Value(5.9280),
        ),
        const VillesCompanion(
          nom: Value('Dijon'),
          codePostal: Value('21000'),
          codeInsee: Value('21231'),
          latitude: Value(47.3220),
          longitude: Value(5.0415),
        ),
      ];
}
