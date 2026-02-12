import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class FitnessVenuesData {
  FitnessVenuesData._();

  static const _catGrandesSalles = '\uD83C\uDFCB\uFE0F Grandes salles & clubs';
  static const _catActivitesGroupe =
      '\uD83E\uDD38 Salles avec activites en groupe';
  static const _catAutresOptions = '\uD83C\uDF1F Autres options';

  static final List<CommerceModel> venues = [
    // ── Grandes salles & clubs ──
    const CommerceModel(
      nom: 'Fitness Park Toulouse Centre',
      categorie: _catGrandesSalles,
      adresse: '20 Rue Bayard, 31000 Toulouse',
      siteWeb: 'https://www.fitnesspark.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Fitness+Park+Toulouse+Centre+20+Rue+Bayard+31000+Toulouse',
      photo: 'assets/images/pochette_fitnesspark.png',
    ),
    const CommerceModel(
      nom: 'Fitness Park Toulouse Purpan',
      categorie: _catGrandesSalles,
      adresse: '2 Av. Didier Daurat, 31700 Blagnac',
      siteWeb: 'https://www.fitnesspark.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Fitness+Park+Toulouse+Purpan+Blagnac',
      photo: 'assets/images/pochette_fitnesspark.png',
    ),
    const CommerceModel(
      nom: 'Fitness Park Toulouse Labege',
      categorie: _catGrandesSalles,
      adresse: 'Centre Commercial Labege 2, 31670 Labege',
      siteWeb: 'https://www.fitnesspark.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Fitness+Park+Labege',
      photo: 'assets/images/pochette_fitnesspark.png',
    ),
    const CommerceModel(
      nom: 'Sporting Form Compans',
      categorie: _catGrandesSalles,
      adresse: '21 Bd de la Marquette, 31000 Toulouse',
      siteWeb: 'https://www.sportingform.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Sporting+Form+Compans+Toulouse',
      photo: 'assets/images/pochette_sportingform.png',
    ),
    const CommerceModel(
      nom: 'Sporting Form Colomiers',
      categorie: _catGrandesSalles,
      adresse: '15 Chem. du Loudet, 31770 Colomiers',
      siteWeb: 'https://www.sportingform.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Sporting+Form+Colomiers',
      photo: 'assets/images/pochette_sportingform.png',
    ),

    // ── Salles avec activites en groupe ──
    const CommerceModel(
      nom: 'Lady Concept',
      categorie: _catActivitesGroupe,
      adresse: '22 Rue Rivals, 31000 Toulouse',
      siteWeb: 'https://www.ladyconcept.com/',
      lienMaps:
          'https://www.google.com/maps/search/Lady+Concept+Toulouse',
      photo: 'assets/images/pochette_ladyconcept.png',
    ),
    const CommerceModel(
      nom: 'Sport&Perf',
      categorie: _catActivitesGroupe,
      adresse: '16 Rue Gabriel Peri, 31000 Toulouse',
      siteWeb: 'https://www.sportetperf.com/',
      lienMaps:
          'https://www.google.com/maps/search/Sport+Perf+Toulouse',
      photo: 'assets/images/pochette_sport&perf.png',
    ),
    const CommerceModel(
      nom: 'Interval',
      categorie: _catActivitesGroupe,
      adresse: '49 All. Jean Jaures, 31000 Toulouse',
      siteWeb: 'https://www.interval.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Interval+Toulouse+Jean+Jaures',
      photo: 'assets/images/pochette_intervl.png',
    ),
    const CommerceModel(
      nom: 'Keepcool Toulouse Centre',
      categorie: _catActivitesGroupe,
      adresse: '6 Rue Ozenne, 31000 Toulouse',
      siteWeb: 'https://www.keepcool.com/',
      lienMaps:
          'https://www.google.com/maps/search/Keepcool+Toulouse+Centre',
      photo: 'assets/images/pochette_keepcool.png',
    ),
    const CommerceModel(
      nom: 'Keepcool Toulouse Compans',
      categorie: _catActivitesGroupe,
      adresse: '5 Bd de la Marquette, 31000 Toulouse',
      siteWeb: 'https://www.keepcool.com/',
      lienMaps:
          'https://www.google.com/maps/search/Keepcool+Toulouse+Compans',
      photo: 'assets/images/pochette_keepcool.png',
    ),
    const CommerceModel(
      nom: 'Movida Fitness',
      categorie: _catActivitesGroupe,
      adresse: '60 Rte de Bayonne, 31300 Toulouse',
      siteWeb: 'https://www.movidafitness.com/',
      lienMaps:
          'https://www.google.com/maps/search/Movida+Fitness+Toulouse',
      photo: 'assets/images/pochette_movida.png',
    ),
    const CommerceModel(
      nom: 'Gym Body Club',
      categorie: _catActivitesGroupe,
      adresse: '34 Rue des Lois, 31000 Toulouse',
      siteWeb: 'https://www.gymbodyclub.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Gym+Body+Club+Toulouse',
      photo: 'assets/images/pochette_gymbody.png',
    ),
    const CommerceModel(
      nom: 'Studio H',
      categorie: _catActivitesGroupe,
      adresse: '12 Rue de la Colombette, 31000 Toulouse',
      siteWeb: 'https://www.studioh-toulouse.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Studio+H+Toulouse',
      photo: 'assets/images/pochette_studioh.png',
    ),
    const CommerceModel(
      nom: "L'Atelier Sport",
      categorie: _catActivitesGroupe,
      adresse: '3 Rue du Lieutenant Colonel Pelissier, 31000 Toulouse',
      siteWeb: 'https://www.lateliersport.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Atelier+Sport+Toulouse',
      photo: 'assets/images/pochette_ateliersport.png',
    ),

    // ── Autres options ──
    const CommerceModel(
      nom: 'UCPA La Cartoucherie',
      categorie: _catAutresOptions,
      adresse: '1 All. Charles de Fitte, 31300 Toulouse',
      siteWeb: 'https://www.ucpa.com/',
      lienMaps:
          'https://www.google.com/maps/search/UCPA+La+Cartoucherie+Toulouse',
      photo: 'assets/images/pochette_ucpa.png',
    ),
  ];
}
