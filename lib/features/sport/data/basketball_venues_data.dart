import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class BasketballVenuesData {
  BasketballVenuesData._();

  static const _catGymnase = '\uD83C\uDFC0 Gymnases';
  static const _catExterieur = '\uD83C\uDFC0 Terrains exterieurs';
  static const _catClub = '\uD83C\uDFC0 Clubs';
  static const _catBanlieue = '\uD83C\uDFC0 Proche de Toulouse';

  static final List<CommerceModel> venues = [
    // ── Gymnases ──
    const CommerceModel(
      nom: 'Palais des Sports Andre Brouat',
      categorie: _catGymnase,
      adresse: '2 Allee Gabriel Bienes, 31400 Toulouse',
      siteWeb: 'https://www.toulouse.fr/web/sports/les-equipements-sportifs',
      lienMaps: 'https://www.google.com/maps/search/Palais+des+Sports+Andre+Brouat+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5860,
      longitude: 1.4620,
    ),
    const CommerceModel(
      nom: 'Gymnase Compans Caffarelli',
      categorie: _catGymnase,
      adresse: 'Esplanade Compans Caffarelli, 31000 Toulouse',
      siteWeb: 'https://www.toulouse.fr/web/sports/les-equipements-sportifs',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Compans+Caffarelli+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6115,
      longitude: 1.4320,
    ),
    const CommerceModel(
      nom: 'Gymnase de la Croix de Pierre',
      categorie: _catGymnase,
      adresse: '2 Rue Jacques Babinet, 31300 Toulouse',
      siteWeb: 'https://www.toulouse.fr/web/sports/les-equipements-sportifs',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Croix+de+Pierre+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5927,
      longitude: 1.4210,
    ),
    const CommerceModel(
      nom: 'Gymnase Pont des Demoiselles',
      categorie: _catGymnase,
      adresse: '10 Rue du Pont des Demoiselles, 31400 Toulouse',
      siteWeb: 'https://www.toulouse.fr/web/sports/les-equipements-sportifs',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Pont+des+Demoiselles+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5930,
      longitude: 1.4630,
    ),
    const CommerceModel(
      nom: 'Gymnase des Argoulets',
      categorie: _catGymnase,
      adresse: '75 Boulevard des Cretes, 31500 Toulouse',
      siteWeb: 'https://www.toulouse.fr/web/sports/les-equipements-sportifs',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+des+Argoulets+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6110,
      longitude: 1.4800,
    ),

    // ── Terrains exterieurs ──
    const CommerceModel(
      nom: 'City Stade Prairie des Filtres',
      categorie: _catExterieur,
      adresse: 'Allee Charles de Fitte, 31000 Toulouse',
      siteWeb: '',
      lienMaps: 'https://www.google.com/maps/search/City+Stade+Prairie+des+Filtres+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5976,
      longitude: 1.4350,
    ),
    const CommerceModel(
      nom: 'Terrain de Basket Ile du Ramier',
      categorie: _catExterieur,
      adresse: 'Ile du Ramier, 31400 Toulouse',
      siteWeb: '',
      lienMaps: 'https://www.google.com/maps/search/terrain+basketball+Ile+du+Ramier+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5830,
      longitude: 1.4370,
    ),
    const CommerceModel(
      nom: 'City Stade Sesquieres',
      categorie: _catExterieur,
      adresse: 'Allee des Foulques, 31200 Toulouse',
      siteWeb: '',
      lienMaps: 'https://www.google.com/maps/search/City+Stade+Sesquieres+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6420,
      longitude: 1.4280,
    ),
    const CommerceModel(
      nom: 'Terrain de Basket Parc de la Maourine',
      categorie: _catExterieur,
      adresse: 'Chemin de la Maourine, 31200 Toulouse',
      siteWeb: '',
      lienMaps: 'https://www.google.com/maps/search/terrain+basket+Parc+Maourine+Toulouse',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6440,
      longitude: 1.4520,
    ),

    // ── Clubs ──
    const CommerceModel(
      nom: 'Toulouse Basket Club (TBC)',
      categorie: _catClub,
      adresse: 'Chemin de Mange-Pommes, 31100 Toulouse',
      siteWeb: 'https://www.toulousebasketclub.fr/',
      lienMaps: 'https://www.google.com/maps/search/Toulouse+Basket+Club+Lafourguette',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5700,
      longitude: 1.4050,
    ),

    // ── Proche de Toulouse ──
    const CommerceModel(
      nom: 'Gymnase Leo Lagrange Blagnac',
      categorie: _catBanlieue,
      adresse: 'Chemin du Ferradou, 31700 Blagnac',
      siteWeb: 'https://www.mairie-blagnac.fr/',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Leo+Lagrange+Blagnac',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6350,
      longitude: 1.3870,
    ),
    const CommerceModel(
      nom: 'Gymnase Didier Vaillant Colomiers',
      categorie: _catBanlieue,
      adresse: 'Avenue du General de Gaulle, 31770 Colomiers',
      siteWeb: 'https://www.ville-colomiers.fr/',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Didier+Vaillant+Colomiers',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6110,
      longitude: 1.3400,
    ),
    const CommerceModel(
      nom: 'Gymnase Municipal de Balma',
      categorie: _catBanlieue,
      adresse: 'Avenue de la Marqueille, 31130 Balma',
      siteWeb: 'https://www.mairie-balma.fr/',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Municipal+Balma',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.6110,
      longitude: 1.4980,
    ),
    const CommerceModel(
      nom: 'Gymnase de Tournefeuille',
      categorie: _catBanlieue,
      adresse: '1 Place de la Mairie, 31170 Tournefeuille',
      siteWeb: 'https://www.mairie-tournefeuille.fr/',
      lienMaps: 'https://www.google.com/maps/search/Gymnase+Municipal+Tournefeuille',
      photo: 'assets/images/shell_sport_basketball.png',
      latitude: 43.5860,
      longitude: 1.3470,
    ),
  ];
}
