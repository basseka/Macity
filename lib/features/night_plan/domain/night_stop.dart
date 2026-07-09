/// Une étape de la « feuille de route » de soirée (dîner, bar, boîte).
enum NightStopKind { dinner, bar, club }

class NightStop {
  final NightStopKind kind;
  final String name;
  final String categorie;
  final String adresse;
  final String ville;
  final double latitude;
  final double longitude;
  final String photo;
  final String lienMaps;
  final bool isPartner;

  /// Distance depuis le lieu de l'événement, en mètres (null si on ne connaît
  /// pas les coordonnées de l'événement — cas fréquent : on classe alors par
  /// partenaire + priorité).
  final int? distanceMeters;

  const NightStop({
    required this.kind,
    required this.name,
    required this.categorie,
    required this.adresse,
    required this.ville,
    required this.latitude,
    required this.longitude,
    required this.photo,
    required this.lienMaps,
    required this.isPartner,
    this.distanceMeters,
  });
}

/// L'itinéraire complet : dîner → [événement] → bar → boîte.
class NightPlan {
  final String ville;
  final NightStop? dinner;
  final NightStop? bar;
  final NightStop? club;

  const NightPlan({
    required this.ville,
    this.dinner,
    this.bar,
    this.club,
  });

  bool get isEmpty => dinner == null && bar == null && club == null;
}
