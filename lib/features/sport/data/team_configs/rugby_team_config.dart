class RugbyTeamConfig {
  /// ESPN team ID.
  final int espnId;
  final String name;
  final String billetterie;
  final String stadium;
  final String league;
  final String city;

  const RugbyTeamConfig({
    required this.espnId,
    required this.name,
    required this.billetterie,
    required this.stadium,
    required this.league,
    required this.city,
  });
}

class RugbyTeamConfigs {
  RugbyTeamConfigs._();

  /// ESPN Top 14 league ID.
  static const espnTop14LeagueId = 270559;

  static const teams = [
    RugbyTeamConfig(
      espnId: 25922,
      name: 'Stade Toulousain',
      billetterie: 'https://billetterie.stadetoulousain.fr',
      stadium: 'Stade Ernest-Wallon',
      league: 'Top 14',
      city: 'Toulouse',
    ),
    RugbyTeamConfig(
      espnId: 25921,
      name: 'Stade Francais Paris',
      billetterie: 'https://billetterie.stade.fr',
      stadium: 'Stade Jean-Bouin',
      league: 'Top 14',
      city: 'Paris',
    ),
    RugbyTeamConfig(
      espnId: 99855,
      name: 'Racing 92',
      billetterie: 'https://billetterie.racing92.fr',
      stadium: 'Paris La Defense Arena',
      league: 'Top 14',
      city: 'Nanterre',
    ),
    RugbyTeamConfig(
      espnId: 143736,
      name: 'Lyon OU',
      billetterie: 'https://billetterie.lourugby.fr',
      stadium: 'Matmut Stadium de Gerland',
      league: 'Top 14',
      city: 'Lyon',
    ),
    RugbyTeamConfig(
      espnId: 25918,
      name: 'Montpellier Herault Rugby',
      billetterie: 'https://billetterie.montpellier-rugby.com',
      stadium: 'GGL Stadium',
      league: 'Top 14',
      city: 'Montpellier',
    ),
    RugbyTeamConfig(
      espnId: 25986,
      name: 'RC Toulon',
      billetterie: 'https://billetterie.rctoulon.com',
      stadium: 'Stade Mayol',
      league: 'Top 14',
      city: 'Toulon',
    ),
    RugbyTeamConfig(
      espnId: 143737,
      name: 'Union Bordeaux-Begles',
      billetterie: 'https://billetterie.ubbrugby.com',
      stadium: 'Stade Chaban-Delmas',
      league: 'Top 14',
      city: 'Bordeaux',
    ),
    RugbyTeamConfig(
      espnId: 25917,
      name: 'ASM Clermont Auvergne',
      billetterie: 'https://billetterie.asm-rugby.com',
      stadium: 'Stade Marcel-Michelin',
      league: 'Top 14',
      city: 'Clermont-Ferrand',
    ),
    RugbyTeamConfig(
      espnId: 25916,
      name: 'Castres Olympique',
      billetterie: 'https://billetterie.castres-olympique.fr',
      stadium: 'Stade Pierre-Fabre',
      league: 'Top 14',
      city: 'Castres',
    ),
    RugbyTeamConfig(
      espnId: 25912,
      name: 'Aviron Bayonnais',
      billetterie: 'https://billetterie.avironsport.com',
      stadium: 'Stade Jean-Dauger',
      league: 'Top 14',
      city: 'Bayonne',
    ),
    RugbyTeamConfig(
      espnId: 119318,
      name: 'Stade Rochelais',
      billetterie: 'https://billetterie.staderochelais.com',
      stadium: 'Stade Marcel-Deflandre',
      league: 'Top 14',
      city: 'La Rochelle',
    ),
    RugbyTeamConfig(
      espnId: 25920,
      name: 'USA Perpignan',
      billetterie: 'https://billetterie.usap.fr',
      stadium: 'Stade Aime-Giral',
      league: 'Top 14',
      city: 'Perpignan',
    ),
    RugbyTeamConfig(
      espnId: 270567,
      name: 'Section Paloise',
      billetterie: 'https://billetterie.section-paloise.com',
      stadium: 'Stade du Hameau',
      league: 'Top 14',
      city: 'Pau',
    ),
    RugbyTeamConfig(
      espnId: 0,
      name: 'Colomiers Rugby',
      billetterie: 'https://billetterie.colomiersrugby.com',
      stadium: 'Stade Michel-Bendichou',
      league: 'Pro D2',
      city: 'Colomiers',
    ),
  ];

  /// Find a team config by its ESPN ID.
  static RugbyTeamConfig? findByEspnId(int espnId) {
    try {
      return teams.firstWhere((t) => t.espnId == espnId);
    } catch (_) {
      return null;
    }
  }
}
