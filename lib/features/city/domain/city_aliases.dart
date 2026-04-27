// Aliases ville centrale -> communes de sa metropole/agglomeration.
// Utilise pour faire remonter les events des communes peripheriques quand
// l'user a selectionne la ville centrale (ex: events Blagnac visibles depuis
// Toulouse, events Pessac depuis Bordeaux).
//
// Source : metropoles & agglos officielles francaises, focus sur les ~10
// communes les plus peuplees de chaque metropole. Liste pragmatique, pas
// exhaustive (ex: Grand Paris a 130 communes, on garde les principales).
//
// Casse : noms en casse standard, le helper [cityAliasesFor] normalise en
// lowercase pour matcher avec ce qu'on a en DB.

const Map<String, List<String>> _metroAliases = {
  // NB: Saint-Denis (93) volontairement absent de cette liste — conflit avec
  // Saint-Denis (974, chef-lieu de la Reunion). Voir entree Reunion ci-dessous.
  'Paris': [
    'Paris', 'Boulogne-Billancourt', 'Argenteuil', 'Montreuil',
    'Nanterre', 'Vitry-sur-Seine', 'Créteil', 'Versailles', 'Aubervilliers',
    'Asnières-sur-Seine', 'Colombes', 'Courbevoie', 'Rueil-Malmaison',
    'Champigny-sur-Marne', 'Saint-Maur-des-Fossés', 'Drancy', 'Issy-les-Moulineaux',
    'Levallois-Perret', 'Neuilly-sur-Seine', 'Antony', 'Noisy-le-Grand',
    'Cergy', 'Clichy', 'Ivry-sur-Seine', 'Pantin', 'Vincennes', 'Suresnes',
    'Puteaux', 'Maisons-Alfort', 'Meudon', 'Bondy',
  ],
  'Marseille': [
    'Marseille', 'Aix-en-Provence', 'Aubagne', 'La Ciotat', 'Marignane',
    'Vitrolles', 'Martigues', 'Salon-de-Provence', 'Istres', 'Allauch',
    'Plan-de-Cuques', 'Cassis', 'Berre-l\'Étang',
  ],
  'Lyon': [
    'Lyon', 'Villeurbanne', 'Vaulx-en-Velin', 'Vénissieux', 'Bron',
    'Caluire-et-Cuire', 'Saint-Priest', 'Décines-Charpieu', 'Meyzieu',
    'Rillieux-la-Pape', 'Écully', 'Oullins', 'Saint-Genis-Laval',
    'Tassin-la-Demi-Lune', 'Givors',
  ],
  'Toulouse': [
    'Toulouse', 'Blagnac', 'Colomiers', 'Tournefeuille', 'Balma', 'Cugnaux',
    'Saint-Orens-de-Gameville', 'L\'Union', 'Ramonville-Saint-Agne',
    'Beauzelle', 'Aussonne', 'Cornebarrieu', 'Castanet-Tolosan', 'Pibrac',
    'Fenouillet', 'Quint-Fonsegrives',
  ],
  'Nice': [
    'Nice', 'Cagnes-sur-Mer', 'Saint-Laurent-du-Var', 'Vence', 'La Trinité',
    'Beaulieu-sur-Mer', 'Villefranche-sur-Mer', 'Saint-Jean-Cap-Ferrat',
    'Èze', 'Cap-d\'Ail', 'La Turbie', 'Tourrette-Levens',
  ],
  'Nantes': [
    'Nantes', 'Saint-Herblain', 'Rezé', 'Saint-Sébastien-sur-Loire', 'Orvault',
    'Vertou', 'Bouguenais', 'Carquefou', 'Couëron', 'La Chapelle-sur-Erdre',
    'Sainte-Luce-sur-Loire', 'Thouaré-sur-Loire', 'Basse-Goulaine',
  ],
  'Strasbourg': [
    'Strasbourg', 'Schiltigheim', 'Illkirch-Graffenstaden', 'Bischheim',
    'Hoenheim', 'Lingolsheim', 'Ostwald', 'Eckbolsheim', 'Mundolsheim',
    'Reichstett', 'Vendenheim', 'La Wantzenau', 'Souffelweyersheim',
  ],
  'Montpellier': [
    'Montpellier', 'Lattes', 'Castelnau-le-Lez', 'Pérols', 'Saint-Jean-de-Védas',
    'Le Crès', 'Jacou', 'Clapiers', 'Vendargues', 'Grabels', 'Juvignac',
    'Saint-Gély-du-Fesc', 'Pignan',
  ],
  'Bordeaux': [
    'Bordeaux', 'Mérignac', 'Pessac', 'Talence', 'Bègles', 'Bruges', 'Cenon',
    'Floirac', 'Le Bouscat', 'Eysines', 'Villenave-d\'Ornon', 'Lormont',
    'Saint-Médard-en-Jalles', 'Gradignan', 'Le Haillan',
  ],
  'Lille': [
    'Lille', 'Roubaix', 'Tourcoing', 'Villeneuve-d\'Ascq', 'Lambersart',
    'Wattrelos', 'Marcq-en-Barœul', 'Mons-en-Barœul', 'La Madeleine',
    'Hellemmes-Lille', 'Lomme', 'Loos', 'Croix', 'Hem', 'Ronchin', 'Wasquehal',
  ],
  'Rennes': [
    'Rennes', 'Cesson-Sévigné', 'Bruz', 'Saint-Grégoire', 'Pacé',
    'Vezin-le-Coquet', 'Chantepie', 'Betton', 'Mordelles', 'Acigné',
    'Chartres-de-Bretagne', 'Le Rheu', 'Saint-Jacques-de-la-Lande',
    'Vern-sur-Seiche',
  ],
  'Rouen': [
    'Rouen', 'Sotteville-lès-Rouen', 'Le Grand-Quevilly', 'Le Petit-Quevilly',
    'Saint-Étienne-du-Rouvray', 'Mont-Saint-Aignan', 'Bois-Guillaume',
    'Bihorel', 'Maromme', 'Déville-lès-Rouen', 'Canteleu', 'Oissel',
  ],
  'Saint-Etienne': [
    'Saint-Étienne', 'Saint-Etienne', 'Saint-Chamond', 'Firminy',
    'Roche-la-Molière', 'Le Chambon-Feugerolles', 'Andrézieux-Bouthéon',
    'Sorbiers', 'Saint-Jean-Bonnefonds', 'Villars', 'Saint-Priest-en-Jarez',
    'La Talaudière',
  ],
  'Toulon': [
    'Toulon', 'La Seyne-sur-Mer', 'Hyères', 'La Garde', 'Ollioules',
    'La Valette-du-Var', 'Six-Fours-les-Plages', 'Le Pradet', 'Carqueiranne',
    'Saint-Mandrier-sur-Mer', 'Le Revest-les-Eaux',
  ],
  'Le Havre': [
    'Le Havre', 'Montivilliers', 'Harfleur', 'Gonfreville-l\'Orcher',
    'Sainte-Adresse', 'Octeville-sur-Mer', 'Fontaine-la-Mallet',
  ],
  'Grenoble': [
    'Grenoble', 'Saint-Martin-d\'Hères', 'Échirolles', 'Fontaine', 'Meylan',
    'Saint-Égrève', 'Eybens', 'La Tronche', 'Seyssinet-Pariset', 'Gières',
    'Domène', 'Sassenage', 'Pont-de-Claix',
  ],
  'Dijon': [
    'Dijon', 'Chenôve', 'Talant', 'Quetigny', 'Longvic', 'Saint-Apollinaire',
    'Fontaine-lès-Dijon', 'Marsannay-la-Côte', 'Plombières-lès-Dijon',
    'Chevigny-Saint-Sauveur',
  ],
  'Angers': [
    'Angers', 'Avrillé', 'Trélazé', 'Les Ponts-de-Cé',
    'Saint-Barthélemy-d\'Anjou', 'Beaucouzé', 'Bouchemaine', 'Mûrs-Erigné',
    'Montreuil-Juigné', 'Sainte-Gemmes-sur-Loire',
  ],
  'Brest': [
    'Brest', 'Guipavas', 'Plougastel-Daoulas', 'Plouzané', 'Le Relecq-Kerhuon',
    'Bohars', 'Gouesnou',
  ],
  'Reims': [
    'Reims', 'Tinqueux', 'Bétheny', 'Cormontreuil', 'Saint-Brice-Courcelles',
    'Bezannes', 'Cernay-lès-Reims',
  ],
  'Clermont-Ferrand': [
    'Clermont-Ferrand', 'Cournon-d\'Auvergne', 'Aubière', 'Beaumont',
    'Chamalières', 'Riom', 'Pont-du-Château', 'Lempdes', 'Romagnat', 'Gerzat',
  ],
  'Nancy': [
    'Nancy', 'Vandœuvre-lès-Nancy', 'Vandoeuvre-lès-Nancy', 'Laxou',
    'Maxéville', 'Jarville-la-Malgrange', 'Tomblaine', 'Essey-lès-Nancy',
    'Saint-Max', 'Malzéville', 'Heillecourt', 'Houdemont',
  ],
  'Metz': [
    'Metz', 'Montigny-lès-Metz', 'Woippy', 'Marly', 'Le Ban-Saint-Martin',
    'Longeville-lès-Metz', 'Saint-Julien-lès-Metz', 'Plappeville',
  ],
  'Avignon': [
    'Avignon', 'Le Pontet', 'Villeneuve-lès-Avignon', 'Vedène', 'Sorgues',
    'Morières-lès-Avignon', 'Caumont-sur-Durance', 'Les Angles',
  ],
  'Nimes': [
    'Nîmes', 'Nimes', 'Caissargues', 'Bouillargues', 'Marguerittes',
    'Saint-Gilles', 'Manduel',
  ],
  'Aix-en-Provence': [
    'Aix-en-Provence', 'Marseille', 'Aubagne', 'Vitrolles', 'Salon-de-Provence',
    'Marignane',
  ],

  // ── DOM-TOM ─────────────────────────────────────────────────────────
  // Pour les DOM, le picker app n'expose qu'un seul chef-lieu par
  // departement. On considere donc que selectionner ce chef-lieu doit
  // remonter les events de tout le DOM (logique "departement", pas
  // "metropole").
  'Fort-de-France': [
    'Fort-de-France', 'Le Lamentin', 'Schœlcher', 'Schoelcher', 'Sainte-Marie',
    'Le Robert', 'Saint-Joseph', 'Ducos', 'Rivière-Salée', 'La Trinité',
    'Sainte-Anne', 'Le Marin', 'Le François', 'Le Diamant', 'Les Trois-Îlets',
    'Saint-Pierre', 'Le Vauclin', 'Le Lorrain', 'Macouba', 'Grand\'Rivière',
    'Basse-Pointe', 'Le Carbet', 'Saint-Esprit', 'Marigot', 'Les Anses-d\'Arlet',
    'Bellefontaine', 'Case-Pilote', 'Fonds-Saint-Denis', 'Gros-Morne',
    'Le Morne-Rouge', 'Le Morne-Vert', 'Rivière-Pilote', 'L\'Ajoupa-Bouillon',
    'Le Prêcheur', 'Sainte-Luce',
  ],
  'Pointe-à-Pitre': [
    'Pointe-à-Pitre', 'Pointe-a-Pitre', 'Les Abymes', 'Baie-Mahault', 'Le Gosier',
    'Petit-Bourg', 'Sainte-Anne', 'Saint-François', 'Le Moule',
    'Capesterre-Belle-Eau', 'Lamentin', 'Morne-à-l\'Eau', 'Sainte-Rose',
    'Anse-Bertrand', 'Port-Louis', 'Petit-Canal', 'Bouillante', 'Pointe-Noire',
    'Vieux-Habitants', 'Vieux-Fort', 'Trois-Rivières', 'Gourbeyre',
    'Saint-Claude', 'Basse-Terre', 'Baillif', 'Capesterre-de-Marie-Galante',
    'Grand-Bourg', 'Saint-Louis', 'La Désirade', 'Terre-de-Bas', 'Terre-de-Haut',
    'Goyave', 'Deshaies',
  ],
  'Cayenne': [
    'Cayenne', 'Matoury', 'Rémire-Montjoly', 'Kourou', 'Macouria',
    'Saint-Laurent-du-Maroni', 'Mana', 'Apatou', 'Awala-Yalimapo', 'Saint-Élie',
    'Régina', 'Saint-Georges', 'Ouanary', 'Camopi', 'Maripasoula', 'Papaichton',
    'Grand-Santi', 'Iracoubo', 'Sinnamary', 'Roura', 'Montsinéry-Tonnegrande',
    'Saül',
  ],
  'Saint-Denis': [
    // Saint-Denis chef-lieu de la Reunion (974). Couvre tout le DOM.
    'Saint-Denis', 'Saint-Paul', 'Saint-Pierre', 'Le Tampon', 'Saint-André',
    'Saint-Louis', 'Le Port', 'Saint-Joseph', 'Saint-Benoît', 'Saint-Leu',
    'La Possession', 'Bras-Panon', 'Saint-Philippe', 'Sainte-Marie',
    'Sainte-Suzanne', 'Sainte-Rose', 'La Plaine-des-Palmistes', 'L\'Étang-Salé',
    'Petite-Île', 'Cilaos', 'Salazie', 'Trois-Bassins', 'Les Avirons',
    'Entre-Deux',
  ],
  'Mamoudzou': [
    'Mamoudzou', 'Koungou', 'Dembéni', 'Bandraboua', 'Tsingoni', 'Sada',
    'Ouangani', 'Chiconi', 'Bandrele', 'Mtsamboro', 'Acoua', 'Bouéni',
    'Chirongui', 'Kani-Kéli', 'Mtsangamouji', 'Pamandzi', 'Dzaoudzi',
  ],
};

/// Retourne la liste des communes faisant partie de la metropole/agglo de
/// [city]. Si [city] n'est ni une ville centrale ni une commune connue d'une
/// metropole, retourne `[city]` (fallback safe : filtre strict).
///
/// Resolution bidirectionnelle : passer "Blagnac" retourne aussi toute la
/// metropole de Toulouse, ce qui permet a un user connecte a une commune
/// peripherique de voir les events de la metropole entiere.
List<String> cityAliasesFor(String city) {
  final lc = city.toLowerCase().trim();
  if (lc.isEmpty) return [city];
  for (final entry in _metroAliases.entries) {
    if (entry.key.toLowerCase() == lc) return entry.value;
    for (final commune in entry.value) {
      if (commune.toLowerCase() == lc) return entry.value;
    }
  }
  return [city];
}

/// Variante pour matcher cote Dart : retourne un Set lowercase pour
/// comparaison rapide `set.contains(otherCity.toLowerCase())`.
Set<String> cityAliasesLcFor(String city) {
  return cityAliasesFor(city).map((c) => c.toLowerCase()).toSet();
}

// Code departement canonique pour chaque chef-lieu de la map d'aliases.
// Sert a desambiguiser les villes homonymes (ex: Saint-Denis 974 vs 93)
// dans les queries Supabase qui filtrent par ville+metropole.
//
// Pour Saint-Denis : on assume systematiquement la Reunion (974) car c'est
// la version exposee dans le picker app `_availableCities`. La banlieue
// parisienne (93) n'est pas dans le picker.
const Map<String, String> _metroDept = {
  'Paris': '75',
  'Marseille': '13',
  'Lyon': '69',
  'Toulouse': '31',
  'Nice': '06',
  'Nantes': '44',
  'Strasbourg': '67',
  'Montpellier': '34',
  'Bordeaux': '33',
  'Lille': '59',
  'Rennes': '35',
  'Rouen': '76',
  'Saint-Etienne': '42',
  'Toulon': '83',
  'Le Havre': '76',
  'Grenoble': '38',
  'Dijon': '21',
  'Angers': '49',
  'Brest': '29',
  'Reims': '51',
  'Clermont-Ferrand': '63',
  'Nancy': '54',
  'Metz': '57',
  'Avignon': '84',
  'Nimes': '30',
  'Aix-en-Provence': '13',
  // DOM
  'Fort-de-France': '972',
  'Pointe-à-Pitre': '971',
  'Cayenne': '973',
  'Saint-Denis': '974',
  'Mamoudzou': '976',
};

/// Retourne le code departement canonique pour [city] si c'est un chef-lieu
/// connu, sinon `null`. Utilise pour desambiguiser les villes homonymes
/// dans les queries Supabase.
String? deptForCity(String city) {
  final lc = city.toLowerCase().trim();
  for (final entry in _metroDept.entries) {
    if (entry.key.toLowerCase() == lc) return entry.value;
  }
  return null;
}
