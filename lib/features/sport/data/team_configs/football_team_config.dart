class FootballTeamConfig {
  /// football-data.org team ID.
  final int teamId;
  final String name;
  final String billetterie;
  final String stadium;

  const FootballTeamConfig({
    required this.teamId,
    required this.name,
    required this.billetterie,
    required this.stadium,
  });
}

class FootballTeamConfigs {
  FootballTeamConfigs._();

  /// football-data.org API token.
  static const apiToken = '568af3e5714f491aaa2f700bcb0c3f54';

  /// Ligue 1 competition ID on football-data.org.
  static const ligue1Id = 2015;

  static const teams = [
    FootballTeamConfig(
      teamId: 511,
      name: 'Toulouse FC',
      billetterie: 'https://billetterie.toulousefc.com',
      stadium: 'Stadium de Toulouse',
    ),
    FootballTeamConfig(
      teamId: 524,
      name: 'Paris Saint-Germain',
      billetterie: 'https://billetterie.psg.fr',
      stadium: 'Parc des Princes',
    ),
    FootballTeamConfig(
      teamId: 516,
      name: 'Olympique de Marseille',
      billetterie: 'https://billetterie.om.fr',
      stadium: 'Stade Velodrome',
    ),
    FootballTeamConfig(
      teamId: 523,
      name: 'Olympique Lyonnais',
      billetterie: 'https://billetterie.ol.fr',
      stadium: 'Groupama Stadium',
    ),
    FootballTeamConfig(
      teamId: 548,
      name: 'AS Monaco',
      billetterie: 'https://billetterie.asmonaco.com',
      stadium: 'Stade Louis II',
    ),
    FootballTeamConfig(
      teamId: 521,
      name: 'LOSC Lille',
      billetterie: 'https://billetterie.losc.fr',
      stadium: 'Stade Pierre-Mauroy',
    ),
    FootballTeamConfig(
      teamId: 522,
      name: 'OGC Nice',
      billetterie: 'https://billetterie.ogcnice.com',
      stadium: 'Allianz Riviera',
    ),
    FootballTeamConfig(
      teamId: 529,
      name: 'Stade Rennais',
      billetterie: 'https://billetterie.staderennais.com',
      stadium: 'Roazhon Park',
    ),
    FootballTeamConfig(
      teamId: 576,
      name: 'RC Strasbourg',
      billetterie: 'https://billetterie.rcstrasbourg.fr',
      stadium: 'Stade de la Meinau',
    ),
    FootballTeamConfig(
      teamId: 546,
      name: 'RC Lens',
      billetterie: 'https://billetterie.rclens.fr',
      stadium: 'Stade Bollaert-Delelis',
    ),
    FootballTeamConfig(
      teamId: 543,
      name: 'FC Nantes',
      billetterie: 'https://billetterie.fcnantes.com',
      stadium: 'Stade de la Beaujoire',
    ),
    FootballTeamConfig(
      teamId: 518,
      name: 'Montpellier HSC',
      billetterie: 'https://billetterie.mhscfoot.com',
      stadium: 'Stade de la Mosson',
    ),
    FootballTeamConfig(
      teamId: 547,
      name: 'Stade de Reims',
      billetterie: 'https://billetterie.stade-de-reims.com',
      stadium: 'Stade Auguste-Delaune',
    ),
    FootballTeamConfig(
      teamId: 512,
      name: 'Stade Brestois 29',
      billetterie: 'https://billetterie.sb29.bzh',
      stadium: 'Stade Francis-Le Ble',
    ),
  ];

  /// Find a team config by its football-data.org ID.
  static FootballTeamConfig? findByTeamId(int teamId) {
    try {
      return teams.firstWhere((t) => t.teamId == teamId);
    } catch (_) {
      return null;
    }
  }
}
