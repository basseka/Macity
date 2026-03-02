import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class GolfVenuesData {
  GolfVenuesData._();

  static const _catGolf = '\u26F3 Golfs';
  static const _catPratique = '\uD83C\uDFCC\uFE0F Practices & initiations';

  static final List<CommerceModel> venues = [
    const CommerceModel(
      nom: 'Golf Club de Toulouse',
      categorie: _catGolf,
      adresse: '2 Chemin de la Planho, 31320 Vieille-Toulouse',
      siteWeb: 'https://www.golfclubdetoulouse.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Golf+Club+de+Toulouse+Vieille+Toulouse',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.5564,
      longitude: 1.4580,
    ),
    const CommerceModel(
      nom: 'UGOLF Toulouse Seilh',
      categorie: _catGolf,
      adresse: '2 Route de Grenade, 31840 Seilh',
      siteWeb: 'https://jouer.golf/golf/ugolf-toulouse-seilh/',
      lienMaps:
          'https://www.google.com/maps/search/UGOLF+Toulouse+Seilh+Route+de+Grenade',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.6694,
      longitude: 1.3547,
    ),
    const CommerceModel(
      nom: 'UGOLF Toulouse La Ramee',
      categorie: _catGolf,
      adresse: 'Avenue du General Eisenhower, 31170 Tournefeuille',
      siteWeb: 'https://www.golfdelaramee.fr/',
      lienMaps:
          'https://www.google.com/maps/search/UGOLF+Toulouse+La+Ramee+Tournefeuille',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.5813,
      longitude: 1.3460,
    ),
    const CommerceModel(
      nom: 'UGOLF Toulouse Teoula',
      categorie: _catGolf,
      adresse: '71 Avenue des Landes, 31830 Plaisance-du-Touch',
      siteWeb: 'https://jouer.golf/golf/ugolf-toulouse-teoula/',
      lienMaps:
          'https://www.google.com/maps/search/UGOLF+Toulouse+Teoula+Plaisance+du+Touch',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.5282,
      longitude: 1.2607,
    ),
    const CommerceModel(
      nom: 'Golf de Palmola',
      categorie: _catGolf,
      adresse: 'Route d\'Albi, 31660 Buzet-sur-Tarn',
      siteWeb: 'https://www.golfdepalmola.com/',
      lienMaps:
          'https://www.google.com/maps/search/Golf+de+Palmola+Buzet+sur+Tarn',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.7768,
      longitude: 1.6310,
    ),
    const CommerceModel(
      nom: 'Estolosa Golf & Country Club',
      categorie: _catGolf,
      adresse: '4 Chemin de Borde-Haute, 31280 Dremil-Lafage',
      siteWeb: 'https://www.estolosa.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Estolosa+Golf+Dremil+Lafage',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.5868,
      longitude: 1.5824,
    ),
    const CommerceModel(
      nom: 'Golf Saint Gabriel',
      categorie: _catGolf,
      adresse: 'Castie, 31850 Montrabe',
      siteWeb: 'https://golfsaintgabriel.com/',
      lienMaps:
          'https://www.google.com/maps/search/Golf+Saint+Gabriel+Montrabe',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.6515,
      longitude: 1.5335,
    ),
    const CommerceModel(
      nom: 'Golf de Garonne',
      categorie: _catPratique,
      adresse: '5 Allee Charles Gandia, 31200 Toulouse',
      siteWeb: 'https://www.golfdegaronne.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Golf+de+Garonne+Toulouse+Sept+Deniers',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.6266,
      longitude: 1.4153,
    ),
    const CommerceModel(
      nom: 'Here We Golf',
      categorie: _catPratique,
      adresse: '1 Rue Delacroix, 31000 Toulouse',
      siteWeb: 'https://en.herewegolf.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Here+We+Golf+Toulouse+Rue+Delacroix',
      photo: 'assets/images/pochette_autre.png',
      latitude: 43.6058,
      longitude: 1.4540,
    ),
  ];
}
