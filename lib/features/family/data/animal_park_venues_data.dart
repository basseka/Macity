class AnimalParkVenue {
  final String id;
  final String name;
  final String description;
  final String group;
  final String adresse;
  final String horaires;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String ticketUrl;
  final String lienMaps;

  const AnimalParkVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.group,
    required this.adresse,
    required this.horaires,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    this.ticketUrl = '',
    required this.lienMaps,
  });
}

class AnimalParkVenuesData {
  AnimalParkVenuesData._();

  static const groupOrder = [
    'Zoo & safari',
    'Parcs animaliers & fermes autour de Toulouse',
    'Parcs animaliers excursion journee',
  ];

  static const venues = <AnimalParkVenue>[
    // ── Zoo & safari ──
    AnimalParkVenue(
      id: 'african_safari',
      name: 'African Safari - Zoo de Plaisance du Touch',
      description: 'Grand parc animalier avec plus de 600 animaux de 80 especes (elephants, lions, zebres, tigres, babouins). Safari en voiture ou visite a pied dans le parc ombrage.',
      group: 'Zoo & safari',
      adresse: 'Chemin du Bois de la Lande, 31830 Plaisance-du-Touch',
      horaires: 'Tous les jours 10h-18h (saison)',
      telephone: '05 61 86 45 03',
      latitude: 43.5530,
      longitude: 1.2645,
      websiteUrl: 'https://www.zoo-africansafari.com/',
      ticketUrl: 'https://www.zoo-africansafari.com/billetterie/',
      lienMaps: 'https://maps.google.com/?q=African+Safari+Zoo+Plaisance+du+Touch',
    ),

    // ── Parcs animaliers & fermes autour de Toulouse ──
    AnimalParkVenue(
      id: 'animaparc_animalier',
      name: 'AnimaParc Occitanie',
      description: 'Parc animalier avec plus de 150 animaux domestiques (lamas, moutons, chevres, lapins), activites enfants et attractions thematiques. Ferme jusqu\'au 4 avril 2026.',
      group: 'Parcs animaliers & fermes autour de Toulouse',
      adresse: 'Lieu-dit En Jacca, 31530 Levignac',
      horaires: 'Mer-Dim 10h-18h (des le 5 avr)',
      telephone: '05 62 79 54 54',
      latitude: 43.6445,
      longitude: 1.1945,
      websiteUrl: 'https://www.animaparc.com/',
      ticketUrl: 'https://www.animaparc.com/billetterie/',
      lienMaps: 'https://maps.google.com/?q=Animaparc+Levignac',
    ),
    AnimalParkVenue(
      id: 'ferme_de_50',
      name: 'La Ferme de 50',
      description: 'Parc animalier et ferme pedagogique avec diverses races domestiques (lamas, poules, chevaux). Ideale pour une sortie en famille.',
      group: 'Parcs animaliers & fermes autour de Toulouse',
      adresse: 'Lieu-dit Cinquante, 31530 Merenvielle',
      horaires: 'Mer-Dim 10h-18h',
      telephone: '06 80 21 69 50',
      latitude: 43.6310,
      longitude: 1.1615,
      websiteUrl: 'https://www.lafermede50.fr/',
      lienMaps: 'https://maps.google.com/?q=La+Ferme+de+50+Merenvielle',
    ),
    AnimalParkVenue(
      id: 'ferme_du_paradis',
      name: 'La Ferme du Paradis',
      description: 'Ferme-parc avec plus d\'une centaine d\'animaux (wallabies, daims, emeus, lamas) et aires de jeux gonflables pour enfants.',
      group: 'Parcs animaliers & fermes autour de Toulouse',
      adresse: 'Lieu-dit Le Paradis, 31370 Rieumes',
      horaires: 'Mer-Dim 10h-18h (saison)',
      telephone: '06 73 19 88 52',
      latitude: 43.4085,
      longitude: 1.1150,
      websiteUrl: 'https://www.lafermeduparadis.fr/',
      lienMaps: 'https://maps.google.com/?q=La+Ferme+du+Paradis+Rieumes',
    ),
    AnimalParkVenue(
      id: 'arche_noe_soly_ange',
      name: 'L\'Arche de Noe de Soly-Ange',
      description: 'Parc animalier associatif avec une grande variete d\'animaux recueillis. Experience plus intimiste et pedagogique.',
      group: 'Parcs animaliers & fermes autour de Toulouse',
      adresse: 'Lieu-dit Soly-Ange, 31410 Lavernose-Lacasse',
      horaires: 'Mer-Dim 10h-17h30',
      telephone: '06 16 48 82 93',
      latitude: 43.3930,
      longitude: 1.2680,
      websiteUrl: 'https://www.arche-de-noe-soly-ange.fr/',
      lienMaps: 'https://maps.google.com/?q=Arche+de+Noe+Soly-Ange+Lavernose-Lacasse',
    ),

    // ── Parcs animaliers excursion journee ──
    AnimalParkVenue(
      id: 'zoo_3_vallees',
      name: 'Zoo des 3 Vallees',
      description: 'Grand parc zoologique avec environ 600 animaux et 70 especes. Zones animales variees et animations pedagogiques.',
      group: 'Parcs animaliers excursion journee',
      adresse: 'Lieu-dit Les Music, 81360 Montredon-Labessonie',
      horaires: 'Avr-Sept 10h-18h',
      telephone: '05 63 75 10 00',
      latitude: 43.7215,
      longitude: 2.3310,
      websiteUrl: 'https://www.zoo3vallees.fr/',
      ticketUrl: 'https://www.zoo3vallees.fr/billetterie/',
      lienMaps: 'https://maps.google.com/?q=Zoo+des+3+Vallees+Montredon-Labessonie',
    ),
  ];
}
