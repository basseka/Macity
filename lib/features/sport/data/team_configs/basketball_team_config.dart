class BasketballTeamConfig {
  final String name;
  final String billetterie;
  final String stadium;
  final String league;
  final String city;

  const BasketballTeamConfig({
    required this.name,
    required this.billetterie,
    required this.stadium,
    required this.league,
    required this.city,
  });
}

class BasketballTeamConfigs {
  BasketballTeamConfigs._();

  static const teams = [
    BasketballTeamConfig(
      name: 'Toulouse Basketball Club',
      billetterie: 'https://www.toulousebasketclub.fr/billetterie',
      stadium: 'Palais des Sports Andre Brouat',
      league: 'NM1',
      city: 'Toulouse',
    ),
    BasketballTeamConfig(
      name: 'Toulouse Metropole Basket (TMB)',
      billetterie: 'https://www.tmbasket.fr/billetterie',
      stadium: 'Gymnase Compans-Caffarelli',
      league: 'LF2',
      city: 'Toulouse',
    ),
    BasketballTeamConfig(
      name: 'Paris Basketball',
      billetterie: 'https://billetterie.parisbasketball.com',
      stadium: 'Adidas Arena',
      league: 'Betclic Elite',
      city: 'Paris',
    ),
    BasketballTeamConfig(
      name: 'LDLC ASVEL',
      billetterie: 'https://billetterie.asvel.com',
      stadium: 'LDLC Arena',
      league: 'Betclic Elite',
      city: 'Villeurbanne',
    ),
    BasketballTeamConfig(
      name: 'SIG Strasbourg',
      billetterie: 'https://billetterie.sigstrasbourg.fr',
      stadium: 'Rhenus Sport',
      league: 'Betclic Elite',
      city: 'Strasbourg',
    ),
    BasketballTeamConfig(
      name: 'AS Monaco Basket',
      billetterie: 'https://billetterie.asmonaco.com/basket',
      stadium: 'Salle Gaston-Medecin',
      league: 'Betclic Elite',
      city: 'Monaco',
    ),
    BasketballTeamConfig(
      name: 'Nanterre 92',
      billetterie: 'https://billetterie.jsa-nanterre.com',
      stadium: 'Palais des Sports Maurice Thorez',
      league: 'Betclic Elite',
      city: 'Nanterre',
    ),
    BasketballTeamConfig(
      name: 'Le Mans Sarthe Basket',
      billetterie: 'https://billetterie.msb.fr',
      stadium: 'Antarès',
      league: 'Betclic Elite',
      city: 'Le Mans',
    ),
    BasketballTeamConfig(
      name: 'Limoges CSP',
      billetterie: 'https://billetterie.limogescsp.com',
      stadium: 'Palais des Sports de Beaublanc',
      league: 'Betclic Elite',
      city: 'Limoges',
    ),
    BasketballTeamConfig(
      name: 'Cholet Basket',
      billetterie: 'https://billetterie.choletbasket.com',
      stadium: 'La Meilleraie',
      league: 'Betclic Elite',
      city: 'Cholet',
    ),
  ];

  /// Find a team config by its name.
  static BasketballTeamConfig? findByName(String name) {
    try {
      return teams.firstWhere(
        (t) => t.name.toLowerCase().contains(name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }
}
