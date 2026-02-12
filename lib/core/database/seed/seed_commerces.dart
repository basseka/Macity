import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';

class SeedCommerces {
  SeedCommerces._();

  static List<CommercesCompanion> get all => [
        ..._parisDayCommerces,
        ..._lyonDayCommerces,
        ..._marseilleDayCommerces,
        ..._toulouseDayCommerces,
        ..._bordeauxDayCommerces,
        ..._niceDayCommerces,
        ..._nantesDayCommerces,
        ..._lilleDayCommerces,
        ..._strasbourgDayCommerces,
        ..._montpellierDayCommerces,
        ..._rennesDayCommerces,
        ..._grenobleDayCommerces,
        ..._rouenDayCommerces,
        ..._toulonDayCommerces,
        ..._dijonDayCommerces,
        // Night
        ..._parisNightCommerces,
        ..._lyonNightCommerces,
        ..._marseilleNightCommerces,
        ..._toulouseNightCommerces,
        ..._bordeauxNightCommerces,
        ..._niceNightCommerces,
        ..._lilleNightCommerces,
        ..._strasbourgNightCommerces,
        ..._montpellierNightCommerces,
        // Family
        ..._parisFamilyCommerces,
        ..._lyonFamilyCommerces,
        ..._marseilleFamilyCommerces,
        ..._toulouseFamilyCommerces,
        ..._bordeauxFamilyCommerces,
        ..._niceFamilyCommerces,
        // Sport
        ..._parisSportCommerces,
        ..._lyonSportCommerces,
        ..._marseilleSportCommerces,
        ..._toulouseSportCommerces,
        ..._bordeauxSportCommerces,
        ..._niceSportCommerces,
      ];

  static CommercesCompanion _c(
    String nom,
    String adresse,
    String ville,
    String cp,
    String cat,
    double lat,
    double lon,
    String horaires,
    bool ouvert,
    bool independant,
    String tel,
  ) {
    return CommercesCompanion(
      nom: Value(nom),
      adresse: Value(adresse),
      ville: Value(ville),
      codePostal: Value(cp),
      categorie: Value(cat),
      latitude: Value(lat),
      longitude: Value(lon),
      horaires: Value(horaires),
      ouvert: Value(ouvert),
      independant: Value(independant),
      telephone: Value(tel),
      lienMaps: Value('https://maps.google.com/?q=$lat,$lon'),
      source: const Value('seed'),
      lastUpdated: Value(DateTime.now().millisecondsSinceEpoch),
      synced: const Value(true),
    );
  }

  // ═══════════════════════════════════════
  // PARIS DAY
  // ═══════════════════════════════════════
  static final _parisDayCommerces = [
    _c('Boulangerie du Marais', '15 Rue des Francs-Bourgeois', 'Paris', '75000', 'Boulangerie', 48.8566, 2.3622, '7h00 - 20h00', true, true, '01 42 72 13 77'),
    _c('Au Pain Quotidien', '33 Rue de Bretagne', 'Paris', '75000', 'Boulangerie', 48.8630, 2.3610, '6h30 - 20h00', true, false, '01 42 78 23 45'),
    _c('Maison Landemaine', '26 Rue des Martyrs', 'Paris', '75000', 'Boulangerie', 48.8795, 2.3393, '7h00 - 20h30', true, true, '01 48 78 17 25'),
    _c('Pharmacie Bastille', '12 Place de la Bastille', 'Paris', '75000', 'Pharmacie', 48.8533, 2.3692, '8h00 - 21h00', true, false, '01 43 07 55 55'),
    _c('Pharmacie Monge', '78 Rue Monge', 'Paris', '75000', 'Pharmacie', 48.8440, 2.3510, '8h30 - 20h30', true, false, '01 43 31 39 44'),
    _c('Le Bouillon Chartier', '7 Rue du Faubourg Montmartre', 'Paris', '75000', 'Restaurant', 48.8720, 2.3430, '11h30 - 22h00', true, true, '01 47 70 86 29'),
    _c('Chez Janou', '2 Rue Roger Verlomme', 'Paris', '75000', 'Restaurant', 48.8555, 2.3660, '12h00 - 14h30, 19h30 - 23h00', true, true, '01 42 72 28 41'),
    _c('Cafe de Flore', '172 Boulevard Saint-Germain', 'Paris', '75000', 'Cafe', 48.8540, 2.3325, '7h30 - 01h30', true, true, '01 45 48 55 26'),
    _c('Le Comptoir General', '80 Quai de Jemmapes', 'Paris', '75000', 'Cafe', 48.8710, 2.3650, '11h00 - 02h00', true, true, '01 44 88 24 48'),
    _c("Bio c' Bon Bastille", '5 Rue de la Roquette', 'Paris', '75000', 'Bio', 48.8535, 2.3705, '9h00 - 21h00', true, false, '01 43 14 09 09'),
    _c('Naturalia Oberkampf', '68 Rue Oberkampf', 'Paris', '75000', 'Bio', 48.8655, 2.3780, '9h00 - 20h30', true, false, '01 43 57 26 90'),
    _c("Fleurs d'Auteuil", "95 Rue d'Auteuil", 'Paris', '75000', 'Fleuriste', 48.8478, 2.2593, '9h00 - 19h30', true, true, '01 46 51 80 99'),
    _c('Coiffirst Saint-Germain', '30 Rue de Buci', 'Paris', '75000', 'Coiffeur', 48.8533, 2.3370, '9h30 - 19h00', true, false, '01 43 29 07 07'),
    _c('Epicerie Rap', '5 Rue des Petits Carreaux', 'Paris', '75000', 'Epicerie', 48.8672, 2.3478, '8h00 - 22h00', true, true, '01 42 33 12 76'),
    _c('Le Ruisseau', '65 Rue du Ruisseau', 'Paris', '75000', 'Restaurant', 48.8930, 2.3440, '12h00 - 14h30, 19h00 - 22h30', true, true, '01 42 64 35 58'),
  ];

  // ═══════════════════════════════════════
  // LYON DAY
  // ═══════════════════════════════════════
  static final _lyonDayCommerces = [
    _c('Boulangerie Jocteur', '102 Grande Rue de la Guillotiere', 'Lyon', '69000', 'Boulangerie', 45.7520, 4.8420, '6h30 - 19h30', true, true, '04 78 72 32 68'),
    _c('Boulangerie du Palais', '8 Place du Change', 'Lyon', '69000', 'Boulangerie', 45.7630, 4.8270, '7h00 - 19h00', true, true, '04 78 37 98 14'),
    _c('Pharmacie des Terreaux', '1 Place des Terreaux', 'Lyon', '69000', 'Pharmacie', 45.7675, 4.8337, '8h30 - 20h00', true, false, '04 78 28 40 40'),
    _c('Pharmacie Bellecour', '10 Place Bellecour', 'Lyon', '69000', 'Pharmacie', 45.7578, 4.8320, '8h00 - 20h00', true, false, '04 78 42 04 52'),
    _c('Bouchon Chez Hugon', '12 Rue Pizay', 'Lyon', '69000', 'Restaurant', 45.7650, 4.8350, '12h00 - 14h00, 19h00 - 22h00', true, true, '04 78 28 10 94'),
    _c('Le Musee', '2 Rue des Forces', 'Lyon', '69000', 'Restaurant', 45.7637, 4.8280, '12h00 - 14h00, 19h30 - 22h30', true, true, '04 78 37 71 54'),
    _c('Cafe des Negociants', '1 Place Francisque Regaud', 'Lyon', '69000', 'Cafe', 45.7630, 4.8345, '7h00 - 01h00', true, true, '04 78 42 50 05'),
    _c('Slake Coffee', '9 Rue de la Monnaie', 'Lyon', '69000', 'Cafe', 45.7645, 4.8285, '8h00 - 18h30', true, true, '04 78 62 94 37'),
    _c('Bio et Sens', '3 Rue Paul Chenavard', 'Lyon', '69000', 'Bio', 45.7660, 4.8330, '9h30 - 19h30', true, true, '04 78 28 65 43'),
    _c('Fleuriste Bellecour', '18 Rue de la Republique', 'Lyon', '69000', 'Fleuriste', 45.7590, 4.8330, '9h00 - 19h00', true, true, '04 78 37 60 22'),
    _c('Coiffeur des Terreaux', "15 Rue d'Algerie", 'Lyon', '69000', 'Coiffeur', 45.7668, 4.8340, '9h00 - 19h00', true, false, '04 78 28 19 55'),
    _c('Epicerie des Halles', '102 Cours Lafayette', 'Lyon', '69000', 'Epicerie', 45.7630, 4.8520, '7h00 - 13h00', true, true, '04 78 62 39 33'),
  ];

  // ═══════════════════════════════════════
  // MARSEILLE DAY
  // ═══════════════════════════════════════
  static final _marseilleDayCommerces = [
    _c('Four des Navettes', '136 Rue Sainte', 'Marseille', '13000', 'Boulangerie', 43.2920, 5.3700, '7h00 - 19h30', true, true, '04 91 33 32 12'),
    _c('Boulangerie Le Panier', '27 Rue du Panier', 'Marseille', '13000', 'Boulangerie', 43.2980, 5.3680, '6h30 - 19h00', true, true, '04 91 91 23 45'),
    _c('Pharmacie du Vieux-Port', '2 Quai du Port', 'Marseille', '13000', 'Pharmacie', 43.2955, 5.3735, '8h00 - 20h00', true, false, '04 91 90 00 60'),
    _c('Pharmacie Castellane', '46 Rue Paradis', 'Marseille', '13000', 'Pharmacie', 43.2870, 5.3780, '8h30 - 19h30', true, false, '04 91 37 02 23'),
    _c('Chez Fonfon', '140 Rue du Vallon des Auffes', 'Marseille', '13000', 'Restaurant', 43.2850, 5.3560, '12h00 - 14h30, 19h30 - 22h00', true, true, '04 91 52 14 38'),
    _c('Le Cafe des Epices', '4 Rue du Lacydon', 'Marseille', '13000', 'Restaurant', 43.2960, 5.3690, '12h00 - 14h00, 20h00 - 22h00', true, true, '04 91 91 22 69'),
    _c('La Caravelle', '34 Quai du Port', 'Marseille', '13000', 'Cafe', 43.2958, 5.3700, '7h00 - 02h00', true, true, '04 91 90 36 64'),
    _c('Bio Vieux-Port', "15 Cours d'Estienne d'Orves", 'Marseille', '13000', 'Bio', 43.2930, 5.3740, '9h00 - 20h00', true, false, '04 91 54 27 83'),
    _c('Fleuriste du Prado', '250 Avenue du Prado', 'Marseille', '13000', 'Fleuriste', 43.2730, 5.3880, '8h30 - 19h30', true, true, '04 91 77 34 56'),
    _c('Coiffure Vieux-Port', '12 Rue de la Republique', 'Marseille', '13000', 'Coiffeur', 43.2965, 5.3720, '9h00 - 19h00', true, false, '04 91 91 56 78'),
    _c("Epicerie l'Ideal", "11 Rue d'Aubagne", 'Marseille', '13000', 'Epicerie', 43.2940, 5.3790, '7h30 - 20h00', true, true, '04 91 33 48 72'),
    _c("L'Aromat", '6 Rue du 3 Septembre', 'Marseille', '13000', 'Restaurant', 43.2928, 5.3748, '12h00 - 14h00, 19h30 - 22h00', true, true, '04 91 42 16 43'),
  ];

  // ═══════════════════════════════════════
  // TOULOUSE DAY
  // ═══════════════════════════════════════
  static final _toulouseDayCommerces = [
    _c('Boulangerie Xavier', '1 Place du Capitole', 'Toulouse', '31000', 'Boulangerie', 43.6045, 1.4440, '6h30 - 20h00', true, true, '05 61 21 32 45'),
    _c('Maison Pillon', "2 Rue d'Austerlitz", 'Toulouse', '31000', 'Boulangerie', 43.6000, 1.4460, '7h00 - 19h30', true, true, '05 61 52 61 73'),
    _c('Pharmacie du Capitole', '25 Place du Capitole', 'Toulouse', '31000', 'Pharmacie', 43.6047, 1.4442, '8h30 - 19h30', true, false, '05 61 21 38 23'),
    _c('Pharmacie Saint-Cyprien', '62 Rue de la Republique', 'Toulouse', '31000', 'Pharmacie', 43.5990, 1.4350, '8h00 - 20h00', true, false, '05 61 42 73 15'),
    _c('Le Bibent', '5 Place du Capitole', 'Toulouse', '31000', 'Cafe', 43.6046, 1.4438, '7h30 - 00h00', true, true, '05 61 23 89 03'),
    _c('Le Genty Magre', '3 Rue Genty Magre', 'Toulouse', '31000', 'Restaurant', 43.6000, 1.4445, '12h00 - 14h00, 19h30 - 22h00', true, true, '05 61 21 38 60'),
    _c('Chez Emile', '13 Place Saint-Georges', 'Toulouse', '31000', 'Restaurant', 43.6020, 1.4470, '12h00 - 14h00, 19h30 - 22h30', true, true, '05 61 21 05 56'),
    _c('Cafe Cerise', '12 Rue Antonin Mercier', 'Toulouse', '31000', 'Cafe', 43.6010, 1.4380, '8h00 - 18h00', true, true, '05 61 42 58 90'),
    _c('Bio Capitole', '18 Rue Saint-Rome', 'Toulouse', '31000', 'Bio', 43.6030, 1.4450, '9h30 - 19h30', true, false, '05 61 23 78 45'),
    _c('Fleuriste Toulouse Centre', '8 Rue Alsace-Lorraine', 'Toulouse', '31000', 'Fleuriste', 43.6035, 1.4460, '9h00 - 19h00', true, true, '05 61 21 66 33'),
    _c('Coiffeur Saint-Etienne', '20 Rue Saint-Etienne', 'Toulouse', '31000', 'Coiffeur', 43.5995, 1.4490, '9h00 - 19h00', true, false, '05 61 53 12 44'),
    _c('Epicerie des Carmes', '30 Place des Carmes', 'Toulouse', '31000', 'Epicerie', 43.5990, 1.4470, '7h30 - 20h00', true, true, '05 61 52 88 12'),
  ];

  // ═══════════════════════════════════════
  // BORDEAUX DAY
  // ═══════════════════════════════════════
  static final _bordeauxDayCommerces = [
    _c('La Toque Cuivree', "6 Cours de l'Intendance", 'Bordeaux', '33000', 'Boulangerie', 44.8420, -0.5760, '7h00 - 19h30', true, true, '05 56 44 21 49'),
    _c('Boulangerie Saint-Pierre', '15 Place Saint-Pierre', 'Bordeaux', '33000', 'Boulangerie', 44.8395, -0.5720, '6h30 - 19h30', true, true, '05 56 52 19 70'),
    _c('Pharmacie des Grands Hommes', 'Place des Grands Hommes', 'Bordeaux', '33000', 'Pharmacie', 44.8430, -0.5770, '8h30 - 20h00', true, false, '05 56 48 03 03'),
    _c('Le Petit Commerce', '22 Rue du Parlement Saint-Pierre', 'Bordeaux', '33000', 'Restaurant', 44.8405, -0.5735, '12h00 - 14h00, 19h30 - 22h00', true, true, '05 56 79 76 58'),
    _c('Le Chapon Fin', '5 Rue Montesquieu', 'Bordeaux', '33000', 'Restaurant', 44.8445, -0.5755, '12h00 - 14h00, 19h30 - 22h00', true, true, '05 56 79 10 10'),
    _c('Cafe Utopia', '5 Place Camille Jullian', 'Bordeaux', '33000', 'Cafe', 44.8390, -0.5730, '10h00 - 02h00', true, true, '05 56 52 71 36'),
    _c('Le Plana', '22 Place de la Victoire', 'Bordeaux', '33000', 'Cafe', 44.8340, -0.5740, '7h00 - 02h00', true, true, '05 56 91 73 23'),
    _c('Bio Chartrons', '12 Rue Notre-Dame', 'Bordeaux', '33000', 'Bio', 44.8510, -0.5710, '9h00 - 20h00', true, true, '05 56 39 78 44'),
    _c('Fleuriste Gambetta', '60 Place Gambetta', 'Bordeaux', '33000', 'Fleuriste', 44.8430, -0.5790, '9h00 - 19h00', true, true, '05 56 44 38 92'),
    _c('Coiffeur Sainte-Catherine', '150 Rue Sainte-Catherine', 'Bordeaux', '33000', 'Coiffeur', 44.8400, -0.5740, '9h30 - 19h00', true, false, '05 56 48 12 33'),
    _c('Epicerie Chartrons', '28 Rue Notre-Dame', 'Bordeaux', '33000', 'Epicerie', 44.8515, -0.5715, '8h00 - 20h30', true, true, '05 56 39 11 22'),
    _c('Pharmacie Saint-Pierre', '8 Place Saint-Pierre', 'Bordeaux', '33000', 'Pharmacie', 44.8398, -0.5722, '8h00 - 19h30', true, false, '05 56 81 07 55'),
  ];

  // ═══════════════════════════════════════
  // NICE DAY
  // ═══════════════════════════════════════
  static final _niceDayCommerces = [
    _c('Boulangerie Espuno', '22 Rue Droite', 'Nice', '06000', 'Boulangerie', 43.6975, 7.2750, '6h30 - 19h00', true, true, '04 93 80 73 74'),
    _c('Boulangerie Auer', '7 Rue Saint-Francois de Paule', 'Nice', '06000', 'Boulangerie', 43.6960, 7.2720, '7h00 - 19h30', true, true, '04 93 85 77 98'),
    _c('Pharmacie Massena', 'Place Massena', 'Nice', '06000', 'Pharmacie', 43.6970, 7.2700, '8h30 - 20h00', true, false, '04 93 87 45 12'),
    _c('Cafe de Turin', '5 Place Garibaldi', 'Nice', '06000', 'Cafe', 43.7010, 7.2800, '8h00 - 23h00', true, true, '04 93 62 29 52'),
    _c('Le Safari', '1 Cours Saleya', 'Nice', '06000', 'Restaurant', 43.6955, 7.2755, '12h00 - 14h30, 19h00 - 22h30', true, true, '04 93 80 18 44'),
    _c('Chez Rene Socca', '2 Rue Miralheti', 'Nice', '06000', 'Restaurant', 43.6970, 7.2780, '9h00 - 21h00', true, true, '04 93 92 05 73'),
    _c('Le Distroit', '8 Rue Raoul Bosio', 'Nice', '06000', 'Cafe', 43.6985, 7.2790, '8h00 - 19h00', true, true, '04 93 62 53 17'),
    _c('Bio Nice Centre', '3 Rue de la Liberte', 'Nice', '06000', 'Bio', 43.6975, 7.2680, '9h00 - 19h30', true, false, '04 93 16 88 42'),
    _c('Fleuriste du Cours', '10 Cours Saleya', 'Nice', '06000', 'Fleuriste', 43.6950, 7.2760, '6h30 - 17h30', true, true, '04 93 85 60 14'),
    _c('Coiffeur Vieux-Nice', '18 Rue de la Prefecture', 'Nice', '06000', 'Coiffeur', 43.6968, 7.2740, '9h00 - 18h30', true, true, '04 93 80 22 67'),
    _c('Epicerie Saleya', '20 Cours Saleya', 'Nice', '06000', 'Epicerie', 43.6952, 7.2752, '7h00 - 20h00', true, true, '04 93 62 77 43'),
    _c('Pharmacie Garibaldi', '2 Place Garibaldi', 'Nice', '06000', 'Pharmacie', 43.7008, 7.2795, '8h00 - 20h00', true, false, '04 93 26 50 33'),
  ];

  // ═══════════════════════════════════════
  // NANTES DAY
  // ═══════════════════════════════════════
  static final _nantesDayCommerces = [
    _c('Boulangerie Pommeraye', '8 Passage Pommeraye', 'Nantes', '44000', 'Boulangerie', 47.2130, -1.5610, '7h00 - 19h30', true, true, '02 40 48 15 23'),
    _c('Boulangerie Bouffay', '5 Place du Bouffay', 'Nantes', '44000', 'Boulangerie', 47.2150, -1.5530, '6h30 - 20h00', true, true, '02 40 47 22 18'),
    _c('La Cigale', '4 Place Graslin', 'Nantes', '44000', 'Restaurant', 47.2133, -1.5625, '7h30 - 00h30', true, true, '02 51 84 94 94'),
    _c('Le 1', '1 Rue Olympe de Gouges', 'Nantes', '44000', 'Restaurant', 47.2105, -1.5570, '12h00 - 14h00, 19h30 - 22h00', true, true, '02 40 08 28 00'),
    _c('Pharmacie Place Royale', '1 Place Royale', 'Nantes', '44000', 'Pharmacie', 47.2140, -1.5590, '8h30 - 19h30', true, false, '02 40 48 73 12'),
    _c('Cafe le Flesselles', '3 Allee Flesselles', 'Nantes', '44000', 'Cafe', 47.2160, -1.5545, '8h00 - 01h00', true, true, '02 40 47 91 98'),
    _c('Le Nid', '1 Place de la Republique', 'Nantes', '44000', 'Cafe', 47.2125, -1.5445, '10h00 - 19h00', true, true, '02 40 35 36 51'),
    _c('Bio Graslin', '6 Rue Piron', 'Nantes', '44000', 'Bio', 47.2135, -1.5630, '9h30 - 19h30', true, false, '02 40 47 65 33'),
    _c('Fleuriste Decre', '3 Place du Commerce', 'Nantes', '44000', 'Fleuriste', 47.2145, -1.5555, '9h00 - 19h00', true, true, '02 40 48 90 22'),
    _c('Coiffeur Bouffay', '12 Rue de la Juiverie', 'Nantes', '44000', 'Coiffeur', 47.2148, -1.5525, '9h00 - 19h00', true, false, '02 40 47 33 89'),
    _c('Epicerie Talensac', 'Marche de Talensac', 'Nantes', '44000', 'Epicerie', 47.2200, -1.5600, '7h00 - 13h30', true, true, '02 40 47 11 56'),
    _c('Pharmacie Bouffay', '8 Rue de la Marne', 'Nantes', '44000', 'Pharmacie', 47.2155, -1.5520, '8h00 - 20h00', true, false, '02 40 47 56 78'),
  ];

  // ═══════════════════════════════════════
  // LILLE DAY
  // ═══════════════════════════════════════
  static final _lilleDayCommerces = [
    _c('Boulangerie Meert', '27 Rue Esquermoise', 'Lille', '59000', 'Boulangerie', 50.6365, 3.0625, '7h30 - 19h30', true, true, '03 20 57 07 44'),
    _c('Boulangerie Paul', '8 Rue de Paris', 'Lille', '59000', 'Boulangerie', 50.6370, 3.0660, '6h30 - 20h00', true, false, '03 20 06 86 48'),
    _c('Pharmacie Grand Place', '3 Grand Place', 'Lille', '59000', 'Pharmacie', 50.6368, 3.0635, '8h30 - 19h30', true, false, '03 20 54 67 89'),
    _c('Estaminet Chez la Vieille', '60 Rue de Gand', 'Lille', '59000', 'Restaurant', 50.6395, 3.0615, '12h00 - 14h30, 19h00 - 22h30', true, true, '03 20 13 81 64'),
    _c('La Chicoree', '15 Place Rihour', 'Lille', '59000', 'Restaurant', 50.6350, 3.0640, '11h30 - 23h00', true, true, '03 20 54 81 52'),
    _c('Cafe Leffe', '18 Place de la Gare', 'Lille', '59000', 'Cafe', 50.6380, 3.0710, '8h00 - 01h00', true, false, '03 20 57 33 21'),
    _c("L'Illustration Cafe", '18 Rue Royale', 'Lille', '59000', 'Cafe', 50.6375, 3.0605, '8h00 - 02h00', true, true, '03 20 12 00 61'),
    _c('Bio Village Lille', '25 Rue de Bethune', 'Lille', '59000', 'Bio', 50.6340, 3.0630, '9h00 - 20h00', true, false, '03 20 06 55 48'),
    _c('Fleuriste Grand Place', '5 Rue des Manneliers', 'Lille', '59000', 'Fleuriste', 50.6370, 3.0630, '9h00 - 19h00', true, true, '03 20 55 12 78'),
    _c('Coiffeur Esquermoise', '40 Rue Esquermoise', 'Lille', '59000', 'Coiffeur', 50.6363, 3.0610, '9h30 - 19h00', true, false, '03 20 31 44 22'),
    _c('Epicerie du Vieux-Lille', '10 Rue de la Monnaie', 'Lille', '59000', 'Epicerie', 50.6405, 3.0605, '8h00 - 20h00', true, true, '03 20 55 88 33'),
    _c('Pharmacie Bethune', '50 Rue de Bethune', 'Lille', '59000', 'Pharmacie', 50.6335, 3.0625, '8h00 - 20h00', true, false, '03 20 54 23 45'),
  ];

  // ═══════════════════════════════════════
  // STRASBOURG DAY
  // ═══════════════════════════════════════
  static final _strasbourgDayCommerces = [
    _c('Boulangerie Naegel', '9 Rue du Fosse des Tanneurs', 'Strasbourg', '67000', 'Boulangerie', 48.5790, 7.7480, '6h30 - 19h00', true, true, '03 88 32 14 85'),
    _c('Boulangerie Woerle', '10 Place de la Cathedrale', 'Strasbourg', '67000', 'Boulangerie', 48.5818, 7.7510, '7h00 - 19h30', true, true, '03 88 32 00 22'),
    _c('Pharmacie de la Cathedrale', '1 Place de la Cathedrale', 'Strasbourg', '67000', 'Pharmacie', 48.5815, 7.7505, '8h30 - 19h30', true, false, '03 88 32 19 87'),
    _c('Maison Kammerzell', '16 Place de la Cathedrale', 'Strasbourg', '67000', 'Restaurant', 48.5820, 7.7510, '12h00 - 14h30, 19h00 - 22h30', true, true, '03 88 32 42 14'),
    _c('Au Pont Corbeau', '21 Quai Saint-Nicolas', 'Strasbourg', '67000', 'Restaurant', 48.5780, 7.7480, '12h00 - 14h00, 19h00 - 22h00', true, true, '03 88 35 60 68'),
    _c('Cafe Brant', "11 Place de l'Universite", 'Strasbourg', '67000', 'Cafe', 48.5830, 7.7620, '7h30 - 23h00', true, true, '03 88 36 12 13'),
    _c("Au Crocodile Cafe", "10 Rue de l'Outre", 'Strasbourg', '67000', 'Cafe', 48.5810, 7.7495, '8h00 - 19h00', true, true, '03 88 32 13 02'),
    _c('Bio Petite France', '5 Rue du Bain aux Plantes', 'Strasbourg', '67000', 'Bio', 48.5790, 7.7420, '9h00 - 19h00', true, true, '03 88 32 78 55'),
    _c('Fleuriste Kleber', '3 Place Kleber', 'Strasbourg', '67000', 'Fleuriste', 48.5835, 7.7455, '8h30 - 19h00', true, true, '03 88 75 10 33'),
    _c('Coiffeur Petite France', '15 Rue des Dentelles', 'Strasbourg', '67000', 'Coiffeur', 48.5793, 7.7430, '9h00 - 19h00', true, true, '03 88 32 45 67'),
    _c('Epicerie Petite France', '8 Rue des Moulins', 'Strasbourg', '67000', 'Epicerie', 48.5795, 7.7440, '7h30 - 20h00', true, true, '03 88 32 33 11'),
    _c('Pharmacie Kleber', '15 Place Kleber', 'Strasbourg', '67000', 'Pharmacie', 48.5837, 7.7460, '8h00 - 20h00', true, false, '03 88 32 66 44'),
  ];

  // ═══════════════════════════════════════
  // MONTPELLIER DAY
  // ═══════════════════════════════════════
  static final _montpellierDayCommerces = [
    _c("Boulangerie L'Epi d'Or", '5 Rue de la Loge', 'Montpellier', '34000', 'Boulangerie', 43.6110, 3.8790, '6h30 - 19h30', true, true, '04 67 60 48 22'),
    _c('Boulangerie de la Comedie', '2 Place de la Comedie', 'Montpellier', '34000', 'Boulangerie', 43.6085, 3.8800, '7h00 - 20h00', true, true, '04 67 58 33 15'),
    _c('Pharmacie de la Comedie', '8 Place de la Comedie', 'Montpellier', '34000', 'Pharmacie', 43.6088, 3.8805, '8h30 - 20h00', true, false, '04 67 92 61 22'),
    _c('Le Petit Jardin', '20 Rue Jean-Jacques Rousseau', 'Montpellier', '34000', 'Restaurant', 43.6120, 3.8730, '12h00 - 14h00, 19h30 - 22h00', true, true, '04 67 60 78 78'),
    _c('La Diligence', '2 Place Petrarque', 'Montpellier', '34000', 'Restaurant', 43.6115, 3.8760, '12h00 - 14h30, 19h00 - 22h30', true, true, '04 67 66 12 21'),
    _c('Cafe de la Mer', '5 Place Jean Jaures', 'Montpellier', '34000', 'Cafe', 43.6100, 3.8770, '7h30 - 01h00', true, true, '04 67 60 55 33'),
    _c('Cafe Joseph', '1 Boulevard Victor Hugo', 'Montpellier', '34000', 'Cafe', 43.6090, 3.8815, '8h00 - 00h00', true, true, '04 67 58 90 11'),
    _c('Bio Antigone', "10 Place du Nombre d'Or", 'Montpellier', '34000', 'Bio', 43.6080, 3.8880, '9h00 - 20h00', true, false, '04 67 64 22 78'),
    _c('Fleuriste Ecusson', '12 Rue Foch', 'Montpellier', '34000', 'Fleuriste', 43.6105, 3.8760, '9h00 - 19h00', true, true, '04 67 92 44 56'),
    _c('Coiffeur Comedie', '3 Rue de la Comedie', 'Montpellier', '34000', 'Coiffeur', 43.6087, 3.8802, '9h30 - 19h00', true, false, '04 67 60 11 89'),
    _c('Epicerie des Arceaux', 'Boulevard des Arceaux', 'Montpellier', '34000', 'Epicerie', 43.6070, 3.8680, '7h00 - 13h00', true, true, '04 67 92 55 22'),
    _c('Pharmacie Antigone', 'Centre Antigone', 'Montpellier', '34000', 'Pharmacie', 43.6078, 3.8875, '8h00 - 20h00', true, false, '04 67 15 98 33'),
  ];

  // ═══════════════════════════════════════
  // RENNES DAY
  // ═══════════════════════════════════════
  static final _rennesDayCommerces = [
    _c('Boulangerie Le Fournil Breton', '3 Rue du Chapitre', 'Rennes', '35000', 'Boulangerie', 48.1120, -1.6830, '6h30 - 19h30', true, true, '02 99 79 32 45'),
    _c('Boulangerie Place des Lices', '10 Place des Lices', 'Rennes', '35000', 'Boulangerie', 48.1130, -1.6810, '7h00 - 19h00', true, true, '02 99 30 47 12'),
    _c('Pharmacie de la Mairie', '2 Rue de la Monnaie', 'Rennes', '35000', 'Pharmacie', 48.1115, -1.6790, '8h30 - 19h30', true, false, '02 99 79 14 67'),
    _c('La Fontaine aux Perles', '96 Rue de la Poterie', 'Rennes', '35000', 'Restaurant', 48.0950, -1.6500, '12h00 - 14h00, 19h30 - 21h30', true, true, '02 99 53 90 90'),
    _c('Cafe des Lices', '12 Place des Lices', 'Rennes', '35000', 'Cafe', 48.1132, -1.6815, '7h30 - 01h00', true, true, '02 99 30 25 80'),
    _c('Bio Sainte-Anne', '15 Rue de Saint-Malo', 'Rennes', '35000', 'Bio', 48.1155, -1.6810, '9h30 - 19h30', true, true, '02 99 38 72 44'),
    _c('Fleuriste Republique', '5 Place de la Republique', 'Rennes', '35000', 'Fleuriste', 48.1105, -1.6780, '9h00 - 19h00', true, true, '02 99 79 55 88'),
    _c('Coiffeur Sainte-Anne', '8 Rue de Bertrand', 'Rennes', '35000', 'Coiffeur', 48.1140, -1.6805, '9h00 - 19h00', true, false, '02 99 30 11 67'),
    _c('Epicerie des Lices', 'Place des Lices', 'Rennes', '35000', 'Epicerie', 48.1128, -1.6808, '7h00 - 13h30', true, true, '02 99 30 44 90'),
    _c('Restaurant Essencia', "22 Rue d'Antrain", 'Rennes', '35000', 'Restaurant', 48.1160, -1.6790, '12h00 - 14h00, 19h00 - 22h00', true, true, '02 99 63 02 12'),
  ];

  // ═══════════════════════════════════════
  // GRENOBLE DAY
  // ═══════════════════════════════════════
  static final _grenobleDayCommerces = [
    _c("Boulangerie de l'Aigle", "3 Place de l'Etoile", 'Grenoble', '38000', 'Boulangerie', 45.1880, 5.7245, '6h30 - 19h30', true, true, '04 76 46 12 33'),
    _c('Boulangerie Victor Hugo', '2 Place Victor Hugo', 'Grenoble', '38000', 'Boulangerie', 45.1870, 5.7250, '7h00 - 19h00', true, true, '04 76 87 22 55'),
    _c('Pharmacie Grenette', 'Place Grenette', 'Grenoble', '38000', 'Pharmacie', 45.1895, 5.7270, '8h30 - 19h30', true, false, '04 76 44 18 90'),
    _c('Cafe de la Table Ronde', '7 Place Saint-Andre', 'Grenoble', '38000', 'Cafe', 45.1920, 5.7280, '7h30 - 01h00', true, true, '04 76 44 51 41'),
    _c('Le Mas Bottero', '1 Rue Auguste Gache', 'Grenoble', '38000', 'Restaurant', 45.1910, 5.7220, '12h00 - 14h00, 19h30 - 22h00', true, true, '04 76 96 77 04'),
    _c('Bio Grenette', '8 Place Grenette', 'Grenoble', '38000', 'Bio', 45.1897, 5.7275, '9h00 - 19h30', true, true, '04 76 44 60 33'),
    _c('Fleuriste Victor Hugo', '12 Place Victor Hugo', 'Grenoble', '38000', 'Fleuriste', 45.1868, 5.7255, '9h00 - 19h00', true, true, '04 76 87 33 44'),
    _c('Coiffeur Saint-Andre', '5 Place Saint-Andre', 'Grenoble', '38000', 'Coiffeur', 45.1918, 5.7278, '9h00 - 19h00', true, false, '04 76 44 22 11'),
    _c('Epicerie Halles Sainte-Claire', 'Halles Sainte-Claire', 'Grenoble', '38000', 'Epicerie', 45.1900, 5.7260, '7h00 - 13h00', true, true, '04 76 87 44 55'),
    _c('Restaurant Marie Margaux', '6 Rue Raoul Blanchard', 'Grenoble', '38000', 'Restaurant', 45.1905, 5.7265, '12h00 - 14h00, 19h30 - 22h00', true, true, '04 76 46 46 46'),
  ];

  // ═══════════════════════════════════════
  // ROUEN DAY
  // ═══════════════════════════════════════
  static final _rouenDayCommerces = [
    _c('Boulangerie du Gros Horloge', '12 Rue du Gros Horloge', 'Rouen', '76000', 'Boulangerie', 49.4410, 1.0920, '7h00 - 19h30', true, true, '02 35 71 23 45'),
    _c('Boulangerie Vieux-Marche', 'Place du Vieux-Marche', 'Rouen', '76000', 'Boulangerie', 49.4425, 1.0870, '6h30 - 19h00', true, true, '02 35 70 15 88'),
    _c('Pharmacie Cathedrale', '5 Rue Grand Pont', 'Rouen', '76000', 'Pharmacie', 49.4400, 1.0940, '8h30 - 19h30', true, false, '02 35 71 56 78'),
    _c('Gill Restaurant', '8 Quai de la Bourse', 'Rouen', '76000', 'Restaurant', 49.4420, 1.0880, '12h00 - 14h00, 19h30 - 22h00', true, true, '02 35 71 16 14'),
    _c('Cafe Victor Hugo', '8 Place du Vieux-Marche', 'Rouen', '76000', 'Cafe', 49.4428, 1.0875, '7h30 - 01h00', true, true, '02 35 88 54 33'),
    _c('Bio Vieux-Marche', '15 Rue Rollon', 'Rouen', '76000', 'Bio', 49.4430, 1.0880, '9h00 - 19h30', true, true, '02 35 70 22 44'),
    _c('Fleuriste Cathedrale', '3 Rue Saint-Romain', 'Rouen', '76000', 'Fleuriste', 49.4405, 1.0940, '9h00 - 19h00', true, true, '02 35 71 80 90'),
    _c('Coiffeur Gros Horloge', '20 Rue du Gros Horloge', 'Rouen', '76000', 'Coiffeur', 49.4412, 1.0925, '9h00 - 19h00', true, false, '02 35 88 12 67'),
    _c('Epicerie Saint-Maclou', 'Rue Martainville', 'Rouen', '76000', 'Epicerie', 49.4395, 1.0990, '7h30 - 20h00', true, true, '02 35 71 44 55'),
    _c('Pharmacie Vieux-Marche', '3 Place du Vieux-Marche', 'Rouen', '76000', 'Pharmacie', 49.4423, 1.0868, '8h00 - 20h00', true, false, '02 35 70 33 22'),
  ];

  // ═══════════════════════════════════════
  // TOULON DAY
  // ═══════════════════════════════════════
  static final _toulonDayCommerces = [
    _c('Boulangerie du Port', '5 Quai Cronstadt', 'Toulon', '83000', 'Boulangerie', 43.1240, 5.9280, '6h30 - 19h30', true, true, '04 94 92 12 33'),
    _c('Boulangerie Liberte', 'Place de la Liberte', 'Toulon', '83000', 'Boulangerie', 43.1245, 5.9310, '7h00 - 19h00', true, true, '04 94 41 55 67'),
    _c('Pharmacie Liberte', '8 Place de la Liberte', 'Toulon', '83000', 'Pharmacie', 43.1248, 5.9315, '8h30 - 20h00', true, false, '04 94 92 45 90'),
    _c('Restaurant Le Lido', 'Anse de Mejan', 'Toulon', '83000', 'Restaurant', 43.1200, 5.9250, '12h00 - 14h30, 19h30 - 22h00', true, true, '04 94 03 38 18'),
    _c('Cafe du Port', '12 Quai Cronstadt', 'Toulon', '83000', 'Cafe', 43.1238, 5.9285, '7h00 - 23h00', true, true, '04 94 41 23 55'),
    _c('Bio Toulon Centre', "15 Rue d'Alger", 'Toulon', '83000', 'Bio', 43.1255, 5.9300, '9h00 - 19h30', true, false, '04 94 92 78 11'),
    _c('Fleuriste du Mourillon', '3 Place du Mourillon', 'Toulon', '83000', 'Fleuriste', 43.1190, 5.9420, '9h00 - 19h00', true, true, '04 94 36 22 44'),
    _c('Coiffeur Liberte', '20 Rue Jean Jaures', 'Toulon', '83000', 'Coiffeur', 43.1250, 5.9295, '9h00 - 19h00', true, false, '04 94 41 56 78'),
    _c('Epicerie du Cours', 'Cours Lafayette', 'Toulon', '83000', 'Epicerie', 43.1260, 5.9330, '7h00 - 13h00', true, true, '04 94 92 33 55'),
    _c('Pharmacie Mourillon', '5 Place du Mourillon', 'Toulon', '83000', 'Pharmacie', 43.1192, 5.9425, '8h00 - 19h30', true, false, '04 94 36 11 33'),
  ];

  // ═══════════════════════════════════════
  // DIJON DAY
  // ═══════════════════════════════════════
  static final _dijonDayCommerces = [
    _c('Boulangerie des Halles', '5 Rue Bannelier', 'Dijon', '21000', 'Boulangerie', 47.3220, 5.0410, '6h30 - 19h30', true, true, '03 80 30 12 45'),
    _c('Boulangerie Mulot et Petitjean', '13 Place Bossuet', 'Dijon', '21000', 'Boulangerie', 47.3240, 5.0430, '7h00 - 19h00', true, true, '03 80 30 07 10'),
    _c('Pharmacie de la Liberte', 'Place de la Liberation', 'Dijon', '21000', 'Pharmacie', 47.3215, 5.0425, '8h30 - 19h30', true, false, '03 80 30 56 78'),
    _c('Chez Leon', '20 Rue des Godrans', 'Dijon', '21000', 'Restaurant', 47.3225, 5.0395, '12h00 - 14h00, 19h00 - 22h00', true, true, '03 80 50 01 07'),
    _c('Le Pre aux Clercs', '13 Place de la Liberation', 'Dijon', '21000', 'Restaurant', 47.3218, 5.0420, '12h00 - 14h00, 19h30 - 22h00', true, true, '03 80 38 05 05'),
    _c('Cafe de la Concorde', '2 Place de la Republique', 'Dijon', '21000', 'Cafe', 47.3235, 5.0390, '7h30 - 01h00', true, true, '03 80 73 55 22'),
    _c('Bio Halles', '12 Rue Quentin', 'Dijon', '21000', 'Bio', 47.3222, 5.0415, '9h00 - 19h30', true, true, '03 80 30 44 67'),
    _c('Fleuriste Darcy', 'Place Darcy', 'Dijon', '21000', 'Fleuriste', 47.3250, 5.0340, '9h00 - 19h00', true, true, '03 80 43 22 11'),
    _c('Coiffeur Liberte', '8 Rue de la Liberte', 'Dijon', '21000', 'Coiffeur', 47.3230, 5.0400, '9h00 - 19h00', true, false, '03 80 30 88 33'),
    _c('Epicerie des Halles', 'Halles de Dijon', 'Dijon', '21000', 'Epicerie', 47.3218, 5.0412, '7h00 - 13h00', true, true, '03 80 30 22 56'),
  ];

  // ═══════════════════════════════════════
  // NIGHT COMMERCES
  // ═══════════════════════════════════════
  static final _parisNightCommerces = [
    _c('Le Syndicat', '51 Rue du Faubourg Saint-Denis', 'Paris', '75000', 'Bar a cocktails', 48.8720, 2.3540, '18h00 - 02h00', true, true, '01 46 07 08 89'),
    _c('Concrete', '69 Port de la Rapee', 'Paris', '75000', 'Discotheque', 48.8370, 2.3650, '23h00 - 07h00', true, false, '01 53 46 00 00'),
    _c('Le Comptoir General Night', '80 Quai de Jemmapes', 'Paris', '75000', 'Bar de nuit', 48.8710, 2.3650, '19h00 - 02h00', true, true, '01 44 88 24 48'),
    _c('Candelaria', '52 Rue de Saintonge', 'Paris', '75000', 'Bar a cocktails', 48.8630, 2.3610, '18h00 - 02h00', true, true, '01 42 74 41 28'),
    _c('Rex Club', '5 Boulevard Poissonniere', 'Paris', '75000', 'Discotheque', 48.8710, 2.3470, '23h30 - 06h00', true, false, '01 42 36 10 96'),
    _c('The Frog & Rosbif', '116 Rue Saint-Denis', 'Paris', '75000', 'Pub', 48.8650, 2.3480, '17h00 - 02h00', true, false, '01 42 36 34 73'),
    _c('Le Shisha Cafe', '15 Rue de la Fontaine au Roi', 'Paris', '75000', 'Bar a chicha', 48.8680, 2.3700, '18h00 - 02h00', true, true, '01 43 57 58 90'),
    _c('Epicerie de nuit Oberkampf', '45 Rue Oberkampf', 'Paris', '75000', 'Epicerie de nuit', 48.8650, 2.3750, '20h00 - 05h00', true, true, '01 48 06 72 33'),
    _c('Franprix Bastille 24h', '3 Rue de la Roquette', 'Paris', '75000', 'Superette 24h', 48.8535, 2.3700, '00h00 - 23h59', true, false, '01 43 14 22 11'),
    _c('Station Total Republique', '15 Boulevard Voltaire', 'Paris', '75000', 'Station-service', 48.8635, 2.3685, '00h00 - 23h59', true, false, '01 47 00 35 22'),
    _c('Tabac de Nuit Chatelet', '5 Rue de Rivoli', 'Paris', '75000', 'Tabac de nuit', 48.8560, 2.3480, '20h00 - 04h00', true, true, '01 42 33 88 55'),
    _c('Hotel du Petit Moulin', '29 Rue de Poitou', 'Paris', '75000', 'Hotel', 48.8630, 2.3625, '00h00 - 23h59', true, false, '01 42 74 10 10'),
    _c('Hotel des Grandes Boulevards', '17 Boulevard Poissonniere', 'Paris', '75000', 'Hotel', 48.8715, 2.3460, '00h00 - 23h59', true, false, '01 85 73 33 33'),
  ];

  static final _lyonNightCommerces = [
    _c('Le Sucre', '50 Quai Rambaud', 'Lyon', '69000', 'Discotheque', 45.7380, 4.8180, '23h00 - 05h00', true, false, '04 78 92 95 00'),
    _c("L'Antiquaire", '20 Rue Hippolyte Flandrin', 'Lyon', '69000', 'Bar a cocktails', 45.7660, 4.8340, '18h00 - 01h00', true, true, '04 72 98 52 17'),
    _c('The Smoking Dog', '16 Rue Lainerie', 'Lyon', '69000', 'Pub', 45.7640, 4.8270, '17h00 - 01h00', true, false, '04 78 28 38 27'),
    _c('Ninkasi Gerland', '267 Rue Marcel Merieux', 'Lyon', '69000', 'Bar', 45.7260, 4.8310, '17h00 - 01h00', true, false, '04 72 76 89 00'),
    _c('Le Chicha Lyon', '12 Rue Ste Catherine', 'Lyon', '69000', 'Bar a chicha', 45.7670, 4.8320, '19h00 - 03h00', true, true, '04 78 39 55 12'),
    _c('Epicerie de nuit Guillotiere', '30 Grande Rue de la Guillotiere', 'Lyon', '69000', 'Epicerie de nuit', 45.7520, 4.8410, '21h00 - 04h00', true, true, '04 78 72 11 23'),
    _c('Station BP Part-Dieu', '50 Boulevard Vivier-Merle', 'Lyon', '69000', 'Station-service', 45.7600, 4.8570, '00h00 - 23h59', true, false, '04 78 62 42 10'),
    _c('Hotel Le Royal', '20 Place Bellecour', 'Lyon', '69000', 'Hotel', 45.7575, 4.8325, '00h00 - 23h59', true, false, '04 78 37 57 31'),
  ];

  static final _marseilleNightCommerces = [
    _c('Le Trolleybus', '24 Quai de Rive Neuve', 'Marseille', '13000', 'Discotheque', 43.2935, 5.3700, '23h00 - 05h00', true, false, '04 91 54 30 45'),
    _c('Carry Nation', '10 Rue Beauvau', 'Marseille', '13000', 'Bar a cocktails', 43.2960, 5.3745, '18h00 - 02h00', true, true, '04 91 33 42 17'),
    _c("O'Malley's", '8 Quai de Rive Neuve', 'Marseille', '13000', 'Pub', 43.2940, 5.3690, '17h00 - 02h00', true, false, '04 91 54 90 75'),
    _c('Bar de la Marine', '15 Quai de Rive Neuve', 'Marseille', '13000', 'Bar de nuit', 43.2938, 5.3695, '18h00 - 02h00', true, true, '04 91 54 95 42'),
    _c('Epicerie de nuit Noailles', "25 Rue d'Aubagne", 'Marseille', '13000', 'Epicerie de nuit', 43.2945, 5.3785, '20h00 - 04h00', true, true, '04 91 48 33 67'),
    _c('Hotel Hermes Vieux-Port', '2 Rue Bonneterie', 'Marseille', '13000', 'Hotel', 43.2960, 5.3730, '00h00 - 23h59', true, false, '04 96 11 63 63'),
  ];

  static final _toulouseNightCommerces = [
    _c('Le Purple', '2 Rue Castellane', 'Toulouse', '31000', 'Discotheque', 43.6010, 1.4460, '23h00 - 05h00', true, false, '05 61 23 49 49'),
    _c('Le Bikini', 'Rue Hermes', 'Toulouse', '31000', 'Discotheque', 43.5720, 1.3900, '22h00 - 05h00', true, false, '05 62 24 09 50'),
    _c('Chez Tonton', '16 Place Saint-Pierre', 'Toulouse', '31000', 'Bar de nuit', 43.6055, 1.4395, '18h00 - 02h00', true, true, '05 61 21 89 54'),
    _c('The London Town', "3 Rue de l'Industrie", 'Toulouse', '31000', 'Pub', 43.6050, 1.4490, '17h00 - 02h00', true, false, '05 61 62 58 37'),
    _c('Epicerie de nuit Saint-Pierre', '10 Place Saint-Pierre', 'Toulouse', '31000', 'Epicerie de nuit', 43.6057, 1.4398, '21h00 - 04h00', true, true, '05 61 23 44 12'),
    _c('Hotel Albert 1er', '8 Rue Rivals', 'Toulouse', '31000', 'Hotel', 43.6045, 1.4435, '00h00 - 23h59', true, false, '05 61 21 17 91'),
  ];

  static final _bordeauxNightCommerces = [
    _c('I.Boat', 'Bassin a flot 1', 'Bordeaux', '33000', 'Discotheque', 44.8580, -0.5600, '22h00 - 05h00', true, false, '05 56 10 48 35'),
    _c('Symbiose', '4 Quai des Chartrons', 'Bordeaux', '33000', 'Bar a cocktails', 44.8500, -0.5700, '18h00 - 02h00', true, true, '05 56 44 95 07'),
    _c('The Connemara', "18 Cours d'Albret", 'Bordeaux', '33000', 'Pub', 44.8380, -0.5790, '17h00 - 02h00', true, false, '05 56 52 82 57'),
    _c('Epicerie de nuit Victoire', '8 Place de la Victoire', 'Bordeaux', '33000', 'Epicerie de nuit', 44.8340, -0.5738, '21h00 - 05h00', true, true, '05 56 91 22 44'),
    _c('Hotel de Seze', '23 Allee de Tourny', 'Bordeaux', '33000', 'Hotel', 44.8440, -0.5780, '00h00 - 23h59', true, false, '05 56 14 16 16'),
  ];

  static final _niceNightCommerces = [
    _c('High Club', '45 Promenade des Anglais', 'Nice', '06000', 'Discotheque', 43.6960, 7.2550, '23h30 - 06h00', true, false, '04 93 87 26 46'),
    _c("Ma Nolan's", '2 Rue Saint-Francois de Paule', 'Nice', '06000', 'Pub', 43.6958, 7.2718, '11h00 - 02h00', true, false, '04 93 80 23 87'),
    _c('Le Shapko', '5 Rue Rossetti', 'Nice', '06000', 'Bar de nuit', 43.6975, 7.2755, '19h00 - 02h30', true, true, '04 93 92 79 57'),
    _c('Epicerie de nuit Garibaldi', '8 Place Garibaldi', 'Nice', '06000', 'Epicerie de nuit', 43.7010, 7.2800, '20h00 - 04h00', true, true, '04 93 26 44 88'),
    _c('Hotel Negresco', '37 Promenade des Anglais', 'Nice', '06000', 'Hotel', 43.6950, 7.2560, '00h00 - 23h59', true, false, '04 93 16 64 00'),
  ];

  static final _lilleNightCommerces = [
    _c('Le Network', '15 Rue du Faisan', 'Lille', '59000', 'Discotheque', 50.6340, 3.0620, '23h00 - 06h00', true, false, '03 20 55 12 00'),
    _c("L'Illustration Bar", '18 Rue Royale', 'Lille', '59000', 'Bar de nuit', 50.6375, 3.0605, '18h00 - 03h00', true, true, '03 20 12 00 61'),
    _c('The Wharf', '15 Quai Wault', 'Lille', '59000', 'Pub', 50.6340, 3.0560, '17h00 - 02h00', true, false, '03 20 54 09 59'),
    _c('Epicerie de nuit Solferino', '30 Rue de Solferino', 'Lille', '59000', 'Epicerie de nuit', 50.6330, 3.0580, '20h00 - 04h00', true, true, '03 20 42 55 89'),
    _c('Hotel Barriere', '777 Bis Pont de Flandres', 'Lille', '59000', 'Hotel', 50.6360, 3.0730, '00h00 - 23h59', true, false, '03 28 14 45 00'),
  ];

  static final _strasbourgNightCommerces = [
    _c('La Kulture', '2 Rue des Soeurs', 'Strasbourg', '67000', 'Discotheque', 48.5810, 7.7500, '23h00 - 05h00', true, false, '03 88 36 16 16'),
    _c('Jeannette et les Cycleux', '30 Rue des Tonneliers', 'Strasbourg', '67000', 'Bar a cocktails', 48.5800, 7.7490, '18h00 - 01h00', true, true, '03 88 23 02 71'),
    _c('The Dubliners', '9 Rue du Faisan', 'Strasbourg', '67000', 'Pub', 48.5825, 7.7465, '16h00 - 02h00', true, false, '03 88 36 57 83'),
    _c('Hotel Cour du Corbeau', '6 Rue des Couples', 'Strasbourg', '67000', 'Hotel', 48.5785, 7.7510, '00h00 - 23h59', true, false, '03 90 00 26 26'),
  ];

  static final _montpellierNightCommerces = [
    _c('Rockstore', '20 Rue de Verdun', 'Montpellier', '34000', 'Discotheque', 43.6095, 3.8810, '22h00 - 05h00', true, false, '04 67 06 80 00'),
    _c('Bar du Grand Hotel du Midi', '22 Boulevard Victor Hugo', 'Montpellier', '34000', 'Bar a cocktails', 43.6080, 3.8815, '18h00 - 01h00', true, false, '04 67 92 69 61'),
    _c('Shakespeare Pub', '6 Rue du Petit Scel', 'Montpellier', '34000', 'Pub', 43.6110, 3.8770, '17h00 - 02h00', true, false, '04 67 60 80 45'),
    _c('Epicerie de nuit Comedie', '5 Rue de la Loge', 'Montpellier', '34000', 'Epicerie de nuit', 43.6105, 3.8785, '21h00 - 04h00', true, true, '04 67 60 33 22'),
  ];

  // ═══════════════════════════════════════
  // FAMILY COMMERCES
  // ═══════════════════════════════════════
  static final _parisFamilyCommerces = [
    _c('Parc Asterix', 'Plailly', 'Paris', '75000', "Parc d'attractions", 49.1364, 2.5722, '10h00 - 18h00', true, false, '08 26 30 10 40'),
    _c("Jardin d'Acclimatation", 'Bois de Boulogne', 'Paris', '75000', 'Aire de jeux', 48.8780, 2.2610, '10h00 - 19h00', true, false, '01 40 67 90 85'),
    _c('UGC Cine Cite Les Halles', '7 Place de la Rotonde', 'Paris', '75000', 'Cinema', 48.8620, 2.3470, '10h00 - 00h00', true, false, '08 92 70 00 00'),
    _c('Bowling Mouffetard', '73 Rue Mouffetard', 'Paris', '75000', 'Bowling', 48.8420, 2.3500, '14h00 - 02h00', true, false, '01 43 31 09 35'),
    _c('Lock Academy', '37 Rue Galilee', 'Paris', '75000', 'Escape game', 48.8710, 2.2990, '10h00 - 23h00', true, true, '01 71 97 83 80'),
    _c('Musee du Louvre', 'Rue de Rivoli', 'Paris', '75000', 'Musee', 48.8606, 2.3376, '9h00 - 18h00', true, false, '01 40 20 50 50'),
    _c('Aquarium de Paris', '5 Avenue Albert de Mun', 'Paris', '75000', 'Aquarium', 48.8625, 2.2930, '10h00 - 19h00', true, false, '01 40 69 23 23'),
    _c('Hippopotamus Bastille', '1 Boulevard Beaumarchais', 'Paris', '75000', 'Restaurant familial', 48.8540, 2.3680, '11h30 - 23h00', true, false, '01 44 61 80 40'),
    _c("McDonald's Champs-Elysees", '140 Avenue des Champs-Elysees', 'Paris', '75000', 'Fast-food', 48.8738, 2.2985, '07h00 - 02h00', true, false, '01 45 63 87 00'),
    _c('Berthillon', "31 Rue Saint-Louis en l'Ile", 'Paris', '75000', 'Glacier', 48.8513, 2.3570, '10h00 - 20h00', true, true, '01 43 54 31 61'),
  ];

  static final _lyonFamilyCommerces = [
    _c("Parc de la Tete d'Or", 'Place General Leclerc', 'Lyon', '69000', 'Aire de jeux', 45.7770, 4.8555, '6h30 - 22h30', true, false, '04 72 69 47 60'),
    _c('Pathe Bellecour', '79 Rue de la Republique', 'Lyon', '69000', 'Cinema', 45.7580, 4.8340, '10h00 - 00h00', true, false, '08 92 69 66 96'),
    _c('Musee des Confluences', '86 Quai Perrache', 'Lyon', '69000', 'Musee', 45.7330, 4.8180, '10h30 - 18h30', true, false, '04 28 38 12 12'),
    _c('Bowling de Lyon', '15 Quai Claude Bernard', 'Lyon', '69000', 'Bowling', 45.7530, 4.8400, '14h00 - 01h00', true, false, '04 78 72 49 34'),
    _c('Laser Quest Lyon', '50 Rue de la Villette', 'Lyon', '69000', 'Laser game', 45.7700, 4.8650, '14h00 - 22h00', true, false, '04 78 03 26 26'),
    _c("Flam's Lyon", '8 Place des Celestins', 'Lyon', '69000', 'Restaurant familial', 45.7590, 4.8310, '11h30 - 23h00', true, false, '04 78 37 04 45'),
    _c('Ninkasi Gerland Fast', '267 Rue Marcel Merieux', 'Lyon', '69000', 'Fast-food', 45.7260, 4.8310, '11h00 - 01h00', true, false, '04 72 76 89 00'),
    _c('Terre Adelice', '1 Place de la Baleine', 'Lyon', '69000', 'Glacier', 45.7640, 4.8270, '11h00 - 23h00', true, true, '04 78 37 36 28'),
  ];

  static final _marseilleFamilyCommerces = [
    _c('OK Corral', 'Route Nationale 8', 'Marseille', '13000', "Parc d'attractions", 43.3700, 5.7400, '10h30 - 18h00', true, false, '04 42 73 80 05'),
    _c('Pathe La Joliette', '54 Boulevard des Dames', 'Marseille', '13000', 'Cinema', 43.3050, 5.3650, '10h00 - 00h00', true, false, '08 92 69 66 96'),
    _c('Mucem', '7 Promenade Robert Laffont', 'Marseille', '13000', 'Musee', 43.2965, 5.3610, '10h00 - 19h00', true, false, '04 84 35 13 13'),
    _c('Bowling du Prado', '30 Avenue du Prado', 'Marseille', '13000', 'Bowling', 43.2780, 5.3830, '14h00 - 02h00', true, false, '04 91 71 23 45'),
    _c('Escape Hunt Marseille', '12 Rue Fortia', 'Marseille', '13000', 'Escape game', 43.2950, 5.3740, '10h00 - 22h00', true, true, '04 91 33 56 78'),
    _c('Quick Vieux-Port', '10 Quai du Port', 'Marseille', '13000', 'Fast-food', 43.2960, 5.3700, '10h00 - 23h00', true, false, '04 91 91 67 89'),
  ];

  static final _toulouseFamilyCommerces = [
    _c("Cite de l'Espace", 'Avenue Jean Gonord', 'Toulouse', '31000', 'Musee', 43.5860, 1.4930, '10h00 - 17h00', true, false, '05 67 22 23 24'),
    _c('Gaumont Wilson', '3 Place du President Thomas Wilson', 'Toulouse', '31000', 'Cinema', 43.6070, 1.4450, '10h00 - 00h00', true, false, '08 92 69 66 96'),
    _c('Get Out Toulouse', '25 Allee Jean Jaures', 'Toulouse', '31000', 'Escape game', 43.6050, 1.4500, '10h00 - 23h00', true, true, '05 61 53 78 90'),
    _c("Bowling de Toulouse", "51 Boulevard de l'Embouchure", 'Toulouse', '31000', 'Bowling', 43.6150, 1.4350, '14h00 - 02h00', true, false, '05 61 62 89 00'),
    _c("McDonald's Capitole", '3 Place du Capitole', 'Toulouse', '31000', 'Fast-food', 43.6045, 1.4440, '07h00 - 01h00', true, false, '05 61 21 99 00'),
  ];

  static final _bordeauxFamilyCommerces = [
    _c('Cite du Vin', '134 Quai de Bacalan', 'Bordeaux', '33000', 'Musee', 44.8620, -0.5510, '10h00 - 19h00', true, false, '05 56 16 20 20'),
    _c('Mega CGR Bordeaux', '13 Rue Georges Bonnac', 'Bordeaux', '33000', 'Cinema', 44.8410, -0.5780, '10h00 - 00h00', true, false, '08 92 68 85 85'),
    _c('Bowling de Bordeaux', '12 Rue Lecocq', 'Bordeaux', '33000', 'Bowling', 44.8370, -0.5720, '14h00 - 02h00', true, false, '05 56 91 12 34'),
    _c('Escape Yourself Bordeaux', '8 Rue du Loup', 'Bordeaux', '33000', 'Escape game', 44.8395, -0.5740, '10h00 - 22h30', true, true, '05 56 44 33 22'),
    _c('Glacier Cadiot-Badie', '26 Allee de Tourny', 'Bordeaux', '33000', 'Glacier', 44.8440, -0.5775, '10h00 - 19h30', true, true, '05 56 44 24 22'),
  ];

  static final _niceFamilyCommerces = [
    _c('Marineland', '306 Avenue Mozart', 'Nice', '06000', 'Parc animalier', 43.6160, 7.0680, '10h00 - 19h00', true, false, '04 93 33 49 49'),
    _c('Pathe Massena', '31 Avenue Jean Medecin', 'Nice', '06000', 'Cinema', 43.7000, 7.2710, '10h00 - 00h00', true, false, '08 92 69 66 96'),
    _c('Musee Marc Chagall', 'Avenue Dr Menard', 'Nice', '06000', 'Musee', 43.7100, 7.2700, '10h00 - 17h00', true, false, '04 93 53 87 20'),
    _c('Fenocchio', '2 Place Rossetti', 'Nice', '06000', 'Glacier', 43.6975, 7.2750, '09h00 - 00h00', true, true, '04 93 80 72 52'),
  ];

  // ═══════════════════════════════════════
  // SPORT COMMERCES
  // ═══════════════════════════════════════
  static final _parisSportCommerces = [
    _c('Club Med Gym Bastille', '5 Rue de la Bastille', 'Paris', '75000', 'Salle de fitness', 48.8535, 2.3695, '7h00 - 22h00', true, false, '01 42 72 45 00'),
    _c('CrossFit Le Marais', '10 Rue des Archives', 'Paris', '75000', 'CrossFit', 48.8580, 2.3540, '7h00 - 21h00', true, true, '01 42 78 56 12'),
    _c('Climbing District', '30 Rue de Meaux', 'Paris', '75000', "Salle d'escalade", 48.8800, 2.3750, '10h00 - 23h00', true, true, '01 42 38 90 20'),
    _c('Piscine Saint-Germain', '12 Rue Lobineau', 'Paris', '75000', 'Piscine', 48.8530, 2.3370, '7h00 - 22h00', true, false, '01 56 81 25 40'),
    _c('Tennis Luxembourg', 'Jardin du Luxembourg', 'Paris', '75000', 'Tennis', 48.8480, 2.3370, '7h30 - 21h00', true, false, '01 43 25 79 18'),
    _c('Stade Charlety', '17 Avenue Pierre de Coubertin', 'Paris', '75000', 'Terrain de foot', 48.8190, 2.3470, '8h00 - 22h00', true, false, '01 44 16 60 00'),
    _c('Yoga Village', '64 Rue de Clichy', 'Paris', '75000', 'Yoga', 48.8820, 2.3310, '7h30 - 21h30', true, true, '01 42 81 11 71'),
    _c('Spa Nuxe Montorgueil', '32 Rue Montorgueil', 'Paris', '75000', 'Spa / Sauna', 48.8640, 2.3480, '10h00 - 21h00', true, false, '01 55 80 71 40'),
    _c('EPI Skatepark', 'Port de la Gare', 'Paris', '75000', 'Skatepark', 48.8300, 2.3710, '8h00 - 22h00', true, false, '01 45 86 55 33'),
    _c('Dojo Shaolin Paris', '8 Rue de la Roquette', 'Paris', '75000', 'Arts martiaux', 48.8540, 2.3720, '10h00 - 21h00', true, true, '01 43 55 88 99'),
  ];

  static final _lyonSportCommerces = [
    _c('Neoness Part-Dieu', 'Centre Part-Dieu', 'Lyon', '69000', 'Salle de fitness', 45.7610, 4.8560, '6h00 - 23h00', true, false, '04 78 62 90 10'),
    _c('CrossFit Lyon 6', '12 Rue Curie', 'Lyon', '69000', 'CrossFit', 45.7700, 4.8500, '7h00 - 21h00', true, true, '04 78 24 56 89'),
    _c('Climb Up Lyon', '85 Rue de Marseille', 'Lyon', '69000', "Salle d'escalade", 45.7480, 4.8450, '10h00 - 23h00', true, true, '04 78 72 89 10'),
    _c('Piscine du Rhone', 'Quai Claude Bernard', 'Lyon', '69000', 'Piscine', 45.7520, 4.8410, '7h00 - 20h00', true, false, '04 78 72 00 55'),
    _c('Tennis Club de Lyon', '6 Boulevard des Belges', 'Lyon', '69000', 'Tennis', 45.7730, 4.8500, '8h00 - 21h00', true, false, '04 78 52 44 22'),
    _c('Stade de Gerland', '353 Avenue Jean Jaures', 'Lyon', '69000', 'Terrain de foot', 45.7260, 4.8310, '8h00 - 22h00', true, false, '04 72 76 60 60'),
    _c('YUJ Yoga Lyon', '5 Rue des Marronniers', 'Lyon', '69000', 'Yoga', 45.7580, 4.8320, '8h00 - 21h00', true, true, '04 78 37 45 12'),
    _c('Spa Les Bains Lyon', '7 Rue de la Fromagerie', 'Lyon', '69000', 'Spa / Sauna', 45.7630, 4.8290, '10h00 - 21h00', true, false, '04 78 28 67 89'),
  ];

  static final _marseilleSportCommerces = [
    _c('Keep Cool Vieux-Port', '20 Quai de Rive Neuve', 'Marseille', '13000', 'Salle de fitness', 43.2935, 5.3700, '6h00 - 23h00', true, false, '04 91 54 33 22'),
    _c("Vertical'Art Marseille", '22 Rue de la Republique', 'Marseille', '13000', "Salle d'escalade", 43.2980, 5.3720, '10h00 - 23h00', true, true, '04 91 91 78 56'),
    _c('Piscine Vallier', 'Boulevard Jacques Saade', 'Marseille', '13000', 'Piscine', 43.2900, 5.3600, '7h00 - 20h00', true, false, '04 91 76 15 27'),
    _c('Stade Velodrome', '3 Boulevard Michelet', 'Marseille', '13000', 'Terrain de foot', 43.2700, 5.3960, '8h00 - 22h00', true, false, '04 91 76 56 09'),
    _c('Yoga Shala Marseille', '15 Rue Venture', 'Marseille', '13000', 'Yoga', 43.2950, 5.3760, '8h00 - 21h00', true, true, '04 91 33 45 67'),
    _c('Bowl du Prado', '120 Avenue du Prado', 'Marseille', '13000', 'Skatepark', 43.2750, 5.3870, '8h00 - 21h00', true, false, '04 91 77 22 33'),
  ];

  static final _toulouseSportCommerces = [
    _c('Fitness Park Toulouse', '50 Allee Jean Jaures', 'Toulouse', '31000', 'Salle de fitness', 43.6050, 1.4500, '6h00 - 23h00', true, false, '05 61 62 55 00'),
    _c('Bloc Session Toulouse', '30 Rue des Amidonniers', 'Toulouse', '31000', "Salle d'escalade", 43.6100, 1.4300, '10h00 - 23h00', true, true, '05 61 42 78 90'),
    _c('Piscine Nakache', 'Ile du Ramier', 'Toulouse', '31000', 'Piscine', 43.5950, 1.4380, '7h00 - 20h00', true, false, '05 61 22 31 69'),
    _c('Stadium de Toulouse', '1 Allee Gabriel Bienes', 'Toulouse', '31000', 'Terrain de foot', 43.5835, 1.4340, '8h00 - 22h00', true, false, '05 34 42 73 73'),
    _c('Yoga Toulouse Centre', '5 Rue des Arts', 'Toulouse', '31000', 'Yoga', 43.6030, 1.4460, '8h00 - 21h00', true, true, '05 61 23 56 78'),
  ];

  static final _bordeauxSportCommerces = [
    _c("L'Appart Fitness Bordeaux", '18 Rue Mably', 'Bordeaux', '33000', 'Salle de fitness', 44.8430, -0.5770, '6h30 - 22h30', true, false, '05 56 48 67 89'),
    _c('Climb Up Bordeaux', '10 Rue Achard', 'Bordeaux', '33000', "Salle d'escalade", 44.8550, -0.5650, '10h00 - 23h00', true, true, '05 56 39 45 67'),
    _c('Piscine Judaique', '164 Rue Judaique', 'Bordeaux', '33000', 'Piscine', 44.8420, -0.5870, '7h00 - 20h00', true, false, '05 56 51 48 30'),
    _c('Stade Chaban-Delmas', 'Place Johnston', 'Bordeaux', '33000', 'Terrain de foot', 44.8280, -0.5850, '8h00 - 22h00', true, false, '05 56 98 33 33'),
    _c('Yoga Bordeaux', '8 Rue des Bahutiers', 'Bordeaux', '33000', 'Yoga', 44.8400, -0.5730, '8h00 - 21h00', true, true, '05 56 44 89 12'),
  ];

  static final _niceSportCommerces = [
    _c('Basic-Fit Nice', '5 Boulevard Victor Hugo', 'Nice', '06000', 'Salle de fitness', 43.6985, 7.2680, '6h00 - 22h30', true, false, '04 93 87 56 78'),
    _c('Piscine Jean Bouin', '20 Rue Jean Allegre', 'Nice', '06000', 'Piscine', 43.7050, 7.2600, '7h00 - 20h00', true, false, '04 93 81 39 95'),
    _c('Tennis Nice Lawn', '5 Avenue Suzanne Lenglen', 'Nice', '06000', 'Tennis', 43.7020, 7.2500, '8h00 - 21h00', true, false, '04 93 86 65 96'),
    _c('Promenade des Anglais', 'Promenade des Anglais', 'Nice', '06000', 'Piste cyclable', 43.6940, 7.2650, '00h00 - 23h59', true, false, ''),
    _c('Yoga Nice Centre', '12 Rue Pastorelli', 'Nice', '06000', 'Yoga', 43.7000, 7.2720, '8h00 - 21h00', true, true, '04 93 62 34 56'),
  ];
}
