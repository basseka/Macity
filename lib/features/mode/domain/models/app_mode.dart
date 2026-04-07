enum AppMode {
  day,
  sport,
  culture,
  family,
  food,
  gaming,
  night,
  tourisme;

  String get label {
    switch (this) {
      case AppMode.day:
        return 'Concerts & Spectacles';
      case AppMode.sport:
        return 'Sport & événements sportifs';
      case AppMode.culture:
        return 'Culture & Arts';
      case AppMode.family:
        return 'En Famille';
      case AppMode.food:
        return 'Food & lifestyle';
      case AppMode.gaming:
        return 'Gaming & pop culture';
      case AppMode.night:
        return 'Nuit & sorties';
      case AppMode.tourisme:
        return 'Tourisme & découvertes';
    }
  }

  String get emoji {
    switch (this) {
      case AppMode.day:
        return '☀️';
      case AppMode.sport:
        return '⚽';
      case AppMode.culture:
        return '🎨';
      case AppMode.family:
        return '👨‍👩‍👧‍👦';
      case AppMode.food:
        return '🍽️';
      case AppMode.gaming:
        return '🎮';
      case AppMode.night:
        return '🌙';
      case AppMode.tourisme:
        return '✈️';
    }
  }

  String get routePath => '/mode/$name';

  static AppMode fromName(String name) {
    return AppMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppMode.day,
    );
  }

  /// Labels courts pour la grille home et la barre de bulles.
  String get shortLabel {
    switch (this) {
      case AppMode.day:
        return 'Concert';
      case AppMode.sport:
        return 'Sport';
      case AppMode.culture:
        return 'Culture';
      case AppMode.family:
        return 'Famille';
      case AppMode.food:
        return 'Food';
      case AppMode.gaming:
        return 'Gaming';
      case AppMode.night:
        return 'Nuit';
      case AppMode.tourisme:
        return 'Tourisme';
    }
  }

  /// Sous-titre descriptif pour les cartes de la page d'accueil.
  String get subtitle {
    switch (this) {
      case AppMode.day:
        return 'Concerts, spectacles, festivals';
      case AppMode.sport:
        return 'Matchs, salles, evenements';
      case AppMode.culture:
        return 'Musees, theatre, expos';
      case AppMode.family:
        return 'Parcs, cinema, jeux';
      case AppMode.food:
        return 'Restaurants, brunchs, bien-etre';
      case AppMode.gaming:
        return 'Arcade, VR, manga, e-sport';
      case AppMode.night:
        return 'Bars, clubs, soirees';
      case AppMode.tourisme:
        return 'Visites, balades, activites';
    }
  }

  static const order = [
    AppMode.day, AppMode.night, AppMode.food, AppMode.sport,
    AppMode.culture, AppMode.family, AppMode.gaming, AppMode.tourisme,
  ];
}
