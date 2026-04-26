// Re-exports de la liste canonique des catégories/sous-catégories d'event.
// Source unique : `create_event_state.dart` — utilisée par :
// - le formulaire de création (dropdown obligatoire)
// - le scan flyer (prompt Claude whitelist alignée manuellement, server-side)
// - le filtre du feed (`_matchesFilter`)
//
// Ce fichier ajoute `kSubcategoryToFilter` : pour chaque sous-categorie écrite
// en BDD (col `categorie` de user_events), on connait le tab+sub-filter du
// feed qui doit l'afficher. C'est ce qui remplace l'ancien matching par
// keywords approximatif.

export 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart'
    show kEventCategories, kSubcategories, categoryToMode;

/// Mapping sous-categorie (valeur ecrite en BDD) → (tab, subFilter) du feed.
/// Une sous-cat peut apparaitre sous plusieurs filtres (ex: 'DJ set' →
/// En Scène/Concerts ET Clubbing/Club & Disco). On retourne donc une liste de
/// destinations.
const kSubcategoryToFilter = <String, List<(String tab, String sub)>>{
  // Musique / Concert
  'Concert':           [('En Scène', 'Concerts')],
  'Festival':          [('En Scène', 'Concerts')],
  'Showcase':          [('En Scène', 'Concerts')],
  'Karaoke':           [('En Scène', 'Concerts'), ('Clubbing', 'Club & Disco')],
  'Opera':             [('En Scène', 'Opéra')],
  'DJ set':            [('Clubbing', 'Club & Disco'), ('En Scène', 'Concerts')],

  // Culturel / Artistique
  'Theatre':           [('En Scène', 'Théâtre')],
  'Expo':              [('Event', 'Salon/expo')],
  'Vernissage':        [('Event', 'Salon/expo')],
  'Visite guidee':     [('Event', 'Salon/expo')],
  'Musee':             [('Event', 'Salon/expo')],
  'Cinema':            [('Event', 'Cinéma')],

  // Danse
  'Cours de danse':    [('En Scène', 'Danse')],
  'Spectacle':         [('En Scène', 'Spectacle'), ('En Scène', 'Danse')],
  'Bal':               [('En Scène', 'Danse')],
  'Battle':            [('En Scène', 'Danse')],
  'Stage':             [('En Scène', 'Danse')],

  // Sport / Fitness
  'Football':          [('Event', 'Sport')],
  'Rugby':             [('Event', 'Sport')],
  'Basketball':        [('Event', 'Sport')],
  'Handball':          [('Event', 'Sport')],
  'Tennis':            [('Event', 'Sport')],
  'Boxe':              [('Event', 'Sport')],
  'Natation':          [('Event', 'Sport')],
  'Courses a pied':    [('Event', 'Sport')],
  'Competition':       [('Event', 'Sport')],
  'Stage de danse':    [('En Scène', 'Danse')],
  'Course':            [('Event', 'Sport')],
  'Yoga':              [('Event', 'Sport')],
  'Fitness':           [('Event', 'Sport')],
  'Autre sport':       [('Event', 'Sport')],

  // Business / Salon
  'Conference':        [('Event', 'Salon/expo')],
  'Networking':        [('Event', 'Salon/expo')],
  'Salon':             [('Event', 'Salon/expo')],
  'Seminaire':         [('Event', 'Salon/expo')],
  'Meetup':            [('Event', 'Salon/expo')],

  // Loisirs / Gaming
  'Tournoi e-sport':   [('Event', 'Salon/expo')],
  'Convention':        [('Event', 'Salon/expo')],
  'Bar a jeux':        [('Clubbing', 'Bar')],
  'LAN party':         [('Event', 'Salon/expo')],
  'Escape game':       [('Event', 'Salon/expo')],

  // Gastronomie
  'Restaurant':        [('Event', 'Food')],
  'Degustation':       [('Event', 'Food')],
  'Brunch':            [('Event', 'Food')],
  'Marche':            [('Event', 'Food')],
  'Food truck':        [('Event', 'Food')],
  'Cours de cuisine':  [('Event', 'Food')],

  // Nuit / Soiree
  'Soiree':            [('Event', 'Soirée')],
  'Soiree privee':     [('Event', 'Soirée')],
  'After work':        [('Event', 'Soirée')],
  'Club':              [('Clubbing', 'Club & Disco')],
  'Bar':               [('Clubbing', 'Bar')],

  // Famille / Enfants
  'Spectacle enfant':  [('Event', 'Famille')],
  'Atelier enfant':    [('Event', 'Famille')],
  'Parc':              [('Event', 'Famille')],
  'Bowling':           [('Event', 'Famille')],
  'Fete foraine':      [('Event', 'Famille')],

  // Fete / Communautaire (mappings pragmatiques)
  'Fete de quartier':  [('Event', 'Soirée')],
  'Braderie':          [('Event', 'Salon/expo')],
  'Vide-grenier':      [('Event', 'Salon/expo')],
  'Carnaval':          [('Event', 'Famille')],
  "Feu d'artifice":    [('Event', 'Soirée')],

  // Bien-etre / Sante
  'Meditation':        [('Event', 'Salon/expo')],
  'Spa':               [('Event', 'Salon/expo')],
  'Randonnee':         [('Event', 'Sport')],
  'Retraite bien-etre': [('Event', 'Salon/expo')],

  // Formation / Atelier
  'Atelier creatif':   [('Event', 'Salon/expo')],
  'Formation pro':     [('Event', 'Salon/expo')],
  'Hackathon':         [('Event', 'Salon/expo')],
  'Workshop':          [('Event', 'Salon/expo')],
};

/// Pour un event avec une sous-categorie donnee, dit s'il match un filtre
/// (tab + sous-filtre). Tab seul (sub=null) match si au moins une destination
/// pointe sur ce tab.
bool matchesFilter(String? subcategorie, {required String tab, String? sub}) {
  if (subcategorie == null || subcategorie.isEmpty) return false;
  final destinations = kSubcategoryToFilter[subcategorie];
  if (destinations == null) return false;
  for (final dest in destinations) {
    if (dest.$1 != tab) continue;
    if (sub == null) return true;
    if (dest.$2 == sub) return true;
  }
  return false;
}
