class EmojiMapper {
  EmojiMapper._();

  // Commerce category emojis
  static const _commerceEmojis = <String, String>{
    'Boulangerie': '🥖',
    'Pharmacie': '💊',
    'Restaurant': '🍽️',
    'Cafe': '☕',
    'Coiffeur': '💇',
    'Fleuriste': '💐',
    'Epicerie': '🛒',
    'Bio': '🌱',
    'Supermarche': '🛒',
    'Librairie': '📚',
    'Boucherie': '🥩',
    'Poissonnerie': '🐟',
    'Banque': '🏦',
    'Pressing': '👔',
    'Opticien': '👓',
    'Veterinaire': '🐾',
    // Night
    'Bar': '🍺',
    'Bar de nuit': '🌙',
    'Discotheque': '🎆',
    'Bar a cocktails': '🍹',
    'Bar a chicha': '💨',
    'Pub': '🍻',
    'Epicerie de nuit': '🌜',
    'Superette 24h': '🏪',
    'Station-service': '⛽',
    'Tabac de nuit': '🚬',
    'Hotel': '🛏️',
    // Family
    "Parc d'attractions": '🎢',
    'Aire de jeux': '🧒',
    'Parc animalier': '🦁',
    'Cinema': '🎬',
    'Bowling': '🎳',
    'Laser game': '🔫',
    'Escape game': '🔐',
    'Musee': '🏛️',
    'Bibliotheque': '📚',
    'Aquarium': '🐠',
    'Restaurant familial': '👨‍👩‍👧‍👦',
    'Fast-food': '🍔',
    'Glacier': '🍦',
    // Sport
    'Salle de fitness': '💪',
    'CrossFit': '🤼',
    "Salle d'escalade": '🧗',
    'Arts martiaux': '🥋',
    'Terrain de foot': '⚽',
    'Terrain de basket': '🏀',
    'Piscine': '🏊',
    'Tennis': '🎾',
    'Parcours sportif': '🏃',
    'Skatepark': '🛹',
    'Piste cyclable': '🚴',
    'Yoga': '🧘',
    'Spa / Sauna': '🧖',
    'Club de foot': '⚽',
    'Terrain de foot en salle': '🥅',
    'Club de rugby': '',
    'Terrain de rugby': '🏟️',
    'Club de basket': '🏀',
    'Club de handball': '🤾',
    'Gymnase': '🏢',
  };

  // Event type emojis
  static const _eventEmojis = <String, String>{
    'Concert': '🎵',
    'Festival': '🎪',
    'Theatre': '🎭',
    'Opera': '🎶',
    'Visites guidees': '🏛️',
    'Expo': '🎨',
    'Vernissage': '🖼️',
    'Animations culturelles': '🎉',
    'A venir': '📅',
    'Rugby': '',
    'Football': '⚽',
    'Basketball': '🏀',
    'Handball': '🤾',
    'Boxe': '🥊',
    'Natation': '🏊',
    'Courses a pied': '🏃',
    "Parc d'attractions": '🎢',
    'Fermes': '🐄',
    'Parcs animaliers': '🦁',
  };

  static String getCommerceEmoji(String category) {
    return _commerceEmojis[category] ?? '🏪';
  }

  static String getEventEmoji(String type) {
    return _eventEmojis[type] ?? '📌';
  }
}
