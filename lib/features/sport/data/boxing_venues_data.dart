import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class BoxingVenuesData {
  BoxingVenuesData._();

  static const _catBoxeAnglaise = '\uD83E\uDD4A Boxe anglaise & sports de combat';
  static const _catMultiBoxe = '\uD83E\uDD4B Multi-boxe & boxe francaise';
  static const _catProcheToulouse = '\uD83C\uDFD9\uFE0F Proche de Toulouse';

  static final List<CommerceModel> venues = [
    // ── Boxe anglaise & sports de combat ──
    const CommerceModel(
      nom: 'Toulouse Fight Club Montaudran',
      categorie: _catBoxeAnglaise,
      adresse: 'Montaudran, 31400 Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Toulouse+Fight+Club+Montaudran',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.5770,
      longitude: 1.4830,
    ),
    const CommerceModel(
      nom: 'Boxing Center Toulouse Minimes',
      categorie: _catBoxeAnglaise,
      adresse: 'Quartier des Minimes, 31200 Toulouse',
      siteWeb: 'https://www.boxingcenter.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Boxing+Center+Toulouse+Minimes',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6280,
      longitude: 1.4350,
    ),
    const CommerceModel(
      nom: 'Boxing Center Toulouse St Cyprien',
      categorie: _catBoxeAnglaise,
      adresse: 'Saint-Cyprien, 31300 Toulouse',
      siteWeb: 'https://www.boxingcenter.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Boxing+Center+Toulouse+Saint+Cyprien',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.5990,
      longitude: 1.4310,
    ),
    const CommerceModel(
      nom: 'Boxing Center Balma Gramont',
      categorie: _catBoxeAnglaise,
      adresse: 'Balma Gramont, 31130 Balma',
      siteWeb: 'https://www.boxingcenter.fr/',
      lienMaps:
          'https://www.google.com/maps/search/Boxing+Center+Balma+Gramont',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6200,
      longitude: 1.4970,
    ),
    const CommerceModel(
      nom: 'BOXOUM',
      categorie: _catBoxeAnglaise,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/BOXOUM+Toulouse',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6047,
      longitude: 1.4442,
    ),
    const CommerceModel(
      nom: 'Ladjal Boxing Club Toulouse',
      categorie: _catBoxeAnglaise,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Ladjal+Boxing+Club+Toulouse',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6100,
      longitude: 1.4380,
    ),
    const CommerceModel(
      nom: 'Royal Boxing Toulouse',
      categorie: _catBoxeAnglaise,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Royal+Boxing+Toulouse',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6020,
      longitude: 1.4500,
    ),
    const CommerceModel(
      nom: 'As Boxing',
      categorie: _catBoxeAnglaise,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/As+Boxing+Toulouse',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.5950,
      longitude: 1.4420,
    ),
    const CommerceModel(
      nom: 'Boxing Club Toulousain',
      categorie: _catBoxeAnglaise,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Boxing+Club+Toulousain',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6080,
      longitude: 1.4460,
    ),

    // ── Multi-boxe & boxe francaise ──
    const CommerceModel(
      nom: 'Toulouse Centre Boxe Francaise Savate',
      categorie: _catMultiBoxe,
      adresse: 'Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Toulouse+Centre+Boxe+Francaise+Savate',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6030,
      longitude: 1.4480,
    ),
    const CommerceModel(
      nom: 'Toulouse Multi Boxing La Faourette',
      categorie: _catMultiBoxe,
      adresse: 'La Faourette, 31100 Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Toulouse+Multi+Boxing+La+Faourette',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.5850,
      longitude: 1.4200,
    ),
    const CommerceModel(
      nom: 'Toulouse Multi Boxing Rangueil',
      categorie: _catMultiBoxe,
      adresse: 'Rangueil, 31400 Toulouse',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Toulouse+Multi+Boxing+Rangueil',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.5700,
      longitude: 1.4600,
    ),

    // ── Proche de Toulouse ──
    const CommerceModel(
      nom: 'Blagnac Boxing Club',
      categorie: _catProcheToulouse,
      adresse: 'Blagnac',
      siteWeb: '',
      lienMaps:
          'https://www.google.com/maps/search/Blagnac+Boxing+Club',
      photo: 'assets/images/pochette_boxe.png',
      latitude: 43.6370,
      longitude: 1.3940,
    ),
  ];
}
