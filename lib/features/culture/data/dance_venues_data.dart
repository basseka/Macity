class DanceVenue {
  final String id;
  final String name;
  final String description;
  final String category;
  final String city;
  final String? websiteUrl;
  final String image;

  const DanceVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    this.websiteUrl,
    required this.image,
  });
}

class DanceVenuesData {
  DanceVenuesData._();

  static const List<DanceVenue> venues = [
    // ── Ecoles generales ──
    DanceVenue(
      id: 'choreographic_centre',
      name: 'Choreographic Centre De Toulouse',
      description: 'Cours de danse pour tous niveaux, pedagogie serieuse au coeur de Toulouse.',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'studio9_toulouse',
      name: 'Studio9 Toulouse - School De Danse',
      description: 'Grande ecole avec plusieurs disciplines et cours varies.',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'le_144_dance_avenue',
      name: 'Le 144 Dance Avenue',
      description: 'Studio de danse pluridisciplinaire (rock, salsa, jazz, hip-hop, etc.).',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'trac_the_school',
      name: 'Trac The School Eric & Aurelie Pradal',
      description: 'Cours danse solo et danse de couple (rock, salsa, boogie, lindy hop).',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'encas_danses_studio',
      name: 'Encas-Danses Studio',
      description: 'Studio dynamique proposant cours, ateliers et stages pour enfants & adultes.',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'studio_duo_danses',
      name: 'Studio Duo Danses',
      description: 'Ecole dediee aux danses de salon et danses en couple (rock, salsa, latines).',
      category: 'Ecole generale',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),

    // ── Specialisations & styles ──
    DanceVenue(
      id: 'studio_hop',
      name: 'Studio Hop',
      description: 'Ecole de danses swing & danses sociales, lieu convivial avec soirees et workshops.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'l_danse_hip_hop',
      name: 'L Danse - Hip Hop Arts',
      description: 'Cours orientes hip-hop & danses urbaines.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'breakin_school',
      name: 'Break\'in School - Ecole de breakdance',
      description: 'Specialisee en breakdance & danses urbaines.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'la_salle',
      name: 'La Salle',
      description: 'Ecole de danse classique et contemporaine a Toulouse.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'la_maison_de_la_danse',
      name: 'La Maison De La Danse',
      description: 'Centre de danse avec cours varies.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'atelier_danse',
      name: 'Atelier Danse',
      description: 'Studio de danse pour differents niveaux.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'dancin_la_roseraie',
      name: 'Danc\'in La Roseraie Dance School Toulouse',
      description: 'Danse pour tous styles & ages.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'ecole_danse_du_busca',
      name: 'Ecole de danse du Busca',
      description: 'Studio de danse locale, ambiance conviviale.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'cote_canal',
      name: 'Cote Canal',
      description: 'Ecole proposant cours de danse dans Toulouse.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'top_danse_ballet_school',
      name: 'Top Danse : Ballet School Toulouse',
      description: 'Ecole de ballet et de danse classique.',
      category: 'Specialisation',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),

    // ── Formation professionnelle ──
    DanceVenue(
      id: 'toulouse_danse_formation',
      name: 'Toulouse Danse Formation',
      description: 'Centre de formation professionnelle en danse (lie a 144 Dance Studio).',
      category: 'Formation pro',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'art_dance_international',
      name: 'Art Dance International',
      description: 'Centre de formation aux metiers de la danse, preparation aux examens techniques.',
      category: 'Formation pro',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),

    // ── Autres ecoles ──
    DanceVenue(
      id: 'place_de_la_danse_cdcn',
      name: 'La Place De La Danse CDCN Toulouse Occitanie',
      description: 'Petite structure de danse contemporaine.',
      category: 'Autre',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
    DanceVenue(
      id: 'unit_dance_school',
      name: 'Unit Dance School',
      description: 'Ecole de danse basee a Toulouse (divers styles).',
      category: 'Autre',
      city: 'Toulouse',
      websiteUrl: null,
      image: 'assets/images/pochette_animation.png',
    ),
  ];
}
