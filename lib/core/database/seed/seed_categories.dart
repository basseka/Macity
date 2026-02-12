import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';

class SeedCategories {
  SeedCategories._();

  static List<CategoriesCompanion> get all => [
        // Base categories
        ..._baseCategories,
        // Night categories
        ..._nightCategories,
        // Family categories
        ..._familyCategories,
        // Sport categories
        ..._sportCategories,
      ];

  static final _baseCategories = [
    const CategoriesCompanion(
      nom: Value('Boulangerie'),
      emoji: Value('🥖'),
      nafCodes: Value('10.71C,10.71D'),
      osmTags: Value('shop=bakery'),
    ),
    const CategoriesCompanion(
      nom: Value('Pharmacie'),
      emoji: Value('💊'),
      nafCodes: Value('47.73Z'),
      osmTags: Value('amenity=pharmacy'),
    ),
    const CategoriesCompanion(
      nom: Value('Restaurant'),
      emoji: Value('🍽️'),
      nafCodes: Value('56.10A'),
      osmTags: Value('amenity=restaurant'),
    ),
    const CategoriesCompanion(
      nom: Value('Cafe'),
      emoji: Value('☕'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=cafe'),
    ),
    const CategoriesCompanion(
      nom: Value('Coiffeur'),
      emoji: Value('💇'),
      nafCodes: Value('96.02A,96.02B'),
      osmTags: Value('shop=hairdresser'),
    ),
    const CategoriesCompanion(
      nom: Value('Fleuriste'),
      emoji: Value('💐'),
      nafCodes: Value('47.76Z'),
      osmTags: Value('shop=florist'),
    ),
    const CategoriesCompanion(
      nom: Value('Epicerie'),
      emoji: Value('🛒'),
      nafCodes: Value('47.11F,47.29Z'),
      osmTags: Value('shop=convenience'),
    ),
    const CategoriesCompanion(
      nom: Value('Bio'),
      emoji: Value('🌱'),
      nafCodes: Value(''),
      osmTags: Value('shop=organic'),
    ),
    const CategoriesCompanion(
      nom: Value('Supermarche'),
      emoji: Value('🛒'),
      nafCodes: Value('47.11A,47.11B,47.11C,47.11D'),
      osmTags: Value('shop=supermarket'),
    ),
    const CategoriesCompanion(
      nom: Value('Librairie'),
      emoji: Value('📚'),
      nafCodes: Value('47.61Z'),
      osmTags: Value('shop=books'),
    ),
    const CategoriesCompanion(
      nom: Value('Boucherie'),
      emoji: Value('🥩'),
      nafCodes: Value('47.22Z'),
      osmTags: Value('shop=butcher'),
    ),
    const CategoriesCompanion(
      nom: Value('Poissonnerie'),
      emoji: Value('🐟'),
      nafCodes: Value('47.23Z'),
      osmTags: Value('shop=seafood'),
    ),
    const CategoriesCompanion(
      nom: Value('Banque'),
      emoji: Value('🏦'),
      nafCodes: Value('64.19Z'),
      osmTags: Value('amenity=bank'),
    ),
    const CategoriesCompanion(
      nom: Value('Pressing'),
      emoji: Value('👔'),
      nafCodes: Value('96.01A,96.01B'),
      osmTags: Value('shop=dry_cleaning'),
    ),
    const CategoriesCompanion(
      nom: Value('Opticien'),
      emoji: Value('👓'),
      nafCodes: Value('47.78A'),
      osmTags: Value('shop=optician'),
    ),
    const CategoriesCompanion(
      nom: Value('Veterinaire'),
      emoji: Value('🐾'),
      nafCodes: Value('75.00Z'),
      osmTags: Value('amenity=veterinary'),
    ),
  ];

  static final _nightCategories = [
    const CategoriesCompanion(
      nom: Value('Bar'),
      emoji: Value('🍺'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=bar'),
    ),
    const CategoriesCompanion(
      nom: Value('Bar de nuit'),
      emoji: Value('🌙'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=bar'),
    ),
    const CategoriesCompanion(
      nom: Value('Discotheque'),
      emoji: Value('🎆'),
      nafCodes: Value('93.29Z'),
      osmTags: Value('amenity=nightclub'),
    ),
    const CategoriesCompanion(
      nom: Value('Bar a cocktails'),
      emoji: Value('🍹'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=bar'),
    ),
    const CategoriesCompanion(
      nom: Value('Bar a chicha'),
      emoji: Value('💨'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=bar'),
    ),
    const CategoriesCompanion(
      nom: Value('Pub'),
      emoji: Value('🍻'),
      nafCodes: Value('56.30Z'),
      osmTags: Value('amenity=pub'),
    ),
    const CategoriesCompanion(
      nom: Value('Epicerie de nuit'),
      emoji: Value('🌜'),
      nafCodes: Value('47.11F'),
      osmTags: Value('shop=convenience'),
    ),
    const CategoriesCompanion(
      nom: Value('Superette 24h'),
      emoji: Value('🏪'),
      nafCodes: Value('47.11C'),
      osmTags: Value('shop=convenience'),
    ),
    const CategoriesCompanion(
      nom: Value('Station-service'),
      emoji: Value('⛽'),
      nafCodes: Value('47.30Z'),
      osmTags: Value('amenity=fuel'),
    ),
    const CategoriesCompanion(
      nom: Value('Tabac de nuit'),
      emoji: Value('🚬'),
      nafCodes: Value('47.26Z'),
      osmTags: Value('shop=tobacco'),
    ),
    const CategoriesCompanion(
      nom: Value('Hotel'),
      emoji: Value('🛏️'),
      nafCodes: Value('55.10Z'),
      osmTags: Value('tourism=hotel'),
    ),
  ];

  static final _familyCategories = [
    const CategoriesCompanion(
      nom: Value("Parc d'attractions"),
      emoji: Value('🎢'),
      nafCodes: Value('93.21Z'),
      osmTags: Value('tourism=theme_park'),
    ),
    const CategoriesCompanion(
      nom: Value('Aire de jeux'),
      emoji: Value('🧒'),
      nafCodes: Value(''),
      osmTags: Value('leisure=playground'),
    ),
    const CategoriesCompanion(
      nom: Value('Parc animalier'),
      emoji: Value('🦁'),
      nafCodes: Value('91.04Z'),
      osmTags: Value('tourism=zoo'),
    ),
    const CategoriesCompanion(
      nom: Value('Cinema'),
      emoji: Value('🎬'),
      nafCodes: Value('59.14Z'),
      osmTags: Value('amenity=cinema'),
    ),
    const CategoriesCompanion(
      nom: Value('Bowling'),
      emoji: Value('🎳'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=bowling_alley'),
    ),
    const CategoriesCompanion(
      nom: Value('Laser game'),
      emoji: Value('🔫'),
      nafCodes: Value('93.29Z'),
      osmTags: Value('leisure=laser_tag'),
    ),
    const CategoriesCompanion(
      nom: Value('Escape game'),
      emoji: Value('🔐'),
      nafCodes: Value('93.29Z'),
      osmTags: Value('leisure=escape_game'),
    ),
    const CategoriesCompanion(
      nom: Value('Musee'),
      emoji: Value('🏛️'),
      nafCodes: Value('91.02Z'),
      osmTags: Value('tourism=museum'),
    ),
    const CategoriesCompanion(
      nom: Value('Bibliotheque'),
      emoji: Value('📚'),
      nafCodes: Value('91.01Z'),
      osmTags: Value('amenity=library'),
    ),
    const CategoriesCompanion(
      nom: Value('Aquarium'),
      emoji: Value('🐠'),
      nafCodes: Value('91.04Z'),
      osmTags: Value('tourism=aquarium'),
    ),
    const CategoriesCompanion(
      nom: Value('Restaurant familial'),
      emoji: Value('👨‍👩‍👧‍👦'),
      nafCodes: Value('56.10A'),
      osmTags: Value('amenity=restaurant'),
    ),
    const CategoriesCompanion(
      nom: Value('Fast-food'),
      emoji: Value('🍔'),
      nafCodes: Value('56.10C'),
      osmTags: Value('amenity=fast_food'),
    ),
    const CategoriesCompanion(
      nom: Value('Glacier'),
      emoji: Value('🍦'),
      nafCodes: Value('56.10C'),
      osmTags: Value('amenity=ice_cream'),
    ),
  ];

  static final _sportCategories = [
    const CategoriesCompanion(
      nom: Value('Salle de fitness'),
      emoji: Value('💪'),
      nafCodes: Value('93.13Z'),
      osmTags: Value('leisure=fitness_centre'),
    ),
    const CategoriesCompanion(
      nom: Value('CrossFit'),
      emoji: Value('🤼'),
      nafCodes: Value('93.13Z'),
      osmTags: Value('leisure=fitness_centre'),
    ),
    const CategoriesCompanion(
      nom: Value("Salle d'escalade"),
      emoji: Value('🧗'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=climbing'),
    ),
    const CategoriesCompanion(
      nom: Value('Arts martiaux'),
      emoji: Value('🥋'),
      nafCodes: Value('93.12Z'),
      osmTags: Value('leisure=sports_centre'),
    ),
    const CategoriesCompanion(
      nom: Value('Terrain de foot'),
      emoji: Value('⚽'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=pitch'),
    ),
    const CategoriesCompanion(
      nom: Value('Terrain de basket'),
      emoji: Value('🏀'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=pitch'),
    ),
    const CategoriesCompanion(
      nom: Value('Piscine'),
      emoji: Value('🏊'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=swimming_pool'),
    ),
    const CategoriesCompanion(
      nom: Value('Tennis'),
      emoji: Value('🎾'),
      nafCodes: Value('93.11Z'),
      osmTags: Value('leisure=pitch'),
    ),
    const CategoriesCompanion(
      nom: Value('Parcours sportif'),
      emoji: Value('🏃'),
      nafCodes: Value(''),
      osmTags: Value('leisure=fitness_station'),
    ),
    const CategoriesCompanion(
      nom: Value('Skatepark'),
      emoji: Value('🛹'),
      nafCodes: Value(''),
      osmTags: Value('leisure=skatepark'),
    ),
    const CategoriesCompanion(
      nom: Value('Piste cyclable'),
      emoji: Value('🚴'),
      nafCodes: Value(''),
      osmTags: Value('highway=cycleway'),
    ),
    const CategoriesCompanion(
      nom: Value('Yoga'),
      emoji: Value('🧘'),
      nafCodes: Value('93.13Z'),
      osmTags: Value('leisure=fitness_centre'),
    ),
    const CategoriesCompanion(
      nom: Value('Spa / Sauna'),
      emoji: Value('🧖'),
      nafCodes: Value('96.04Z'),
      osmTags: Value('leisure=spa'),
    ),
  ];
}
