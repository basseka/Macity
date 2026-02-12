class HandballTeamConfig {
  final String name;
  final String billetterie;
  final String stadium;
  final String league;
  final String city;

  const HandballTeamConfig({
    required this.name,
    required this.billetterie,
    required this.stadium,
    required this.league,
    required this.city,
  });
}

class HandballTeamConfigs {
  HandballTeamConfigs._();

  static const teams = [
    HandballTeamConfig(
      name: 'Fenix Toulouse Handball',
      billetterie: 'https://billetterie.fenixtoulouse.fr',
      stadium: 'Palais des Sports Andre Brouat',
      league: 'Liqui Moly StarLigue',
      city: 'Toulouse',
    ),
    HandballTeamConfig(
      name: 'Paris Saint-Germain Handball',
      billetterie: 'https://billetterie.psg.fr/handball',
      stadium: 'Stade Pierre de Coubertin',
      league: 'Liqui Moly StarLigue',
      city: 'Paris',
    ),
    HandballTeamConfig(
      name: 'Montpellier Handball',
      billetterie: 'https://billetterie.montpellierhandball.com',
      stadium: 'Palais des Sports Rene Bougnol',
      league: 'Liqui Moly StarLigue',
      city: 'Montpellier',
    ),
    HandballTeamConfig(
      name: 'HBC Nantes',
      billetterie: 'https://billetterie.hbcnantes.com',
      stadium: 'H Arena - Palais des Sports de Beaulieu',
      league: 'Liqui Moly StarLigue',
      city: 'Nantes',
    ),
    HandballTeamConfig(
      name: 'PAUC Handball',
      billetterie: 'https://billetterie.pauc-handball.com',
      stadium: 'Arena du Pays d\'Aix',
      league: 'Liqui Moly StarLigue',
      city: 'Aix-en-Provence',
    ),
  ];

  /// Find a team config by its name.
  static HandballTeamConfig? findByName(String name) {
    try {
      return teams.firstWhere(
        (t) => t.name.toLowerCase().contains(name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }
}
