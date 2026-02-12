# MaCity - Document de Design

> **Version** : 1.0.4+5
> **Plateforme** : Android & iOS
> **Framework** : Flutter 3.38.9 / Dart 3.10.8
> **Date** : Fevrier 2026

---

## 1. Vue d'ensemble

**MaCity** est une application mobile de decouverte locale centree sur Toulouse et son agglomeration. Elle permet aux utilisateurs d'explorer les evenements, lieux et activites de leur ville a travers **7 modes thematiques**.

L'application combine des donnees temps reel (APIs publiques) avec des lieux curates manuellement pour offrir une experience riche meme hors connexion.

---

## 2. Architecture technique

### 2.1 Stack technologique

| Couche | Technologie |
|--------|-------------|
| UI Framework | Flutter (Material 3) |
| State Management | Riverpod (StateProvider, FutureProvider, FutureProvider.family) |
| Navigation | GoRouter (declaratif, ShellRoute) |
| Base de donnees locale | Drift ORM (SQLite) |
| Modeles | Freezed (immutables, code generation) |
| HTTP Client | Dio |
| Backend | Supabase (auth + evenements utilisateur) |
| Serialisation | json_serializable / json_annotation |

### 2.2 Architecture des dossiers

```
lib/
  app.dart                          # Widget racine ProviderScope + MaterialApp
  main.dart                         # Point d'entree

  core/
    config/                         # Configuration (env, Supabase)
    constants/                      # Constantes API et app
    database/                       # Drift ORM (tables, DAOs, seed)
    network/                        # Dio client, intercepteurs, connectivity
    router/                         # GoRouter configuration
    theme/                          # Systeme de themes (7 modes)
    utils/                          # Utilitaires (date, emoji, haversine, normalisation)
    widgets/                        # Widgets partages (CommerceRowCard, EventRowCard, etc.)

  features/
    auth/                           # Authentification Instagram OAuth
    city/                           # Selection de ville (geo.gouv.fr API)
    commerce/                       # Registre des commerces (SIRENE + OSM)
    day/                            # Mode Concerts & Spectacles
    sport/                          # Mode Sport & evenements sportifs
    culture/                        # Mode Culture & Arts
    family/                         # Mode En Famille
    food/                           # Mode Food & lifestyle
    gaming/                         # Mode Gaming & pop culture
    night/                          # Mode Nuit & sorties
    home/                           # Ecran d'accueil
    mode/                           # Shell de navigation inter-modes
    likes/                          # Systeme de favoris
    splash/                         # Ecran de demarrage
```

### 2.3 Pattern par feature

Chaque feature suit le pattern **Data / Domain / Presentation / State** :

```
feature/
  data/
    *_category_data.dart            # Categories et sous-categories statiques
    *_venues_data.dart              # Donnees curates (lieux, evenements)
    *_service.dart                  # Services API
  domain/
    models/                         # Modeles Freezed
  presentation/
    *_screen.dart                   # Ecran principal du mode
    widgets/                        # Cards et composants specifiques
  state/
    *_provider.dart                 # Riverpod providers
```

---

## 3. Navigation

### 3.1 Arbre de navigation

```
/splash                             # SplashScreen (point d'entree)
  |
  v
/home                               # HomeScreen (selection de mode)
  |
  +-- /instagram-callback           # OAuth redirect
  |
  +-- /mode/  (ShellRoute: ModeShell)
       |-- /mode/day                # Concerts & Spectacles
       |-- /mode/sport              # Sport & evenements sportifs
       |-- /mode/culture            # Culture & Arts
       |-- /mode/family             # En Famille
       |-- /mode/food               # Food & lifestyle
       |-- /mode/gaming             # Gaming & pop culture
       +-- /mode/night              # Nuit & sorties
```

### 3.2 Navigation intra-mode

Chaque mode suit le flux :
1. **Grille de sous-categories** (GridView 3 colonnes, cards avec image/gradient + compteur)
2. **Clic sur une categorie** → affichage de la **liste de lieux/evenements**
3. **Bouton "Categories"** → retour a la grille

Le `ModeShell` encapsule tous les ecrans de mode avec :
- Un header (emoji + nom du mode + bouton retour)
- Un chip bar horizontal pour naviguer entre modes
- Un swipe detector pour changer de mode par glissement

---

## 4. Systeme de themes

### 4.1 Theme global

- **Seed color** : `#7B2D8E` (violet)
- **Background** : `#F8F0FA` (violet clair)
- **Material 3** avec `useMaterial3: true`
- Police : Roboto

### 4.2 Themes par mode (ModeTheme)

Chaque mode possede un jeu de couleurs complet :

| Mode | Couleur primaire | Couleur sombre | Background |
|------|-----------------|----------------|------------|
| **Day** (Concerts) | `#7B2D8E` violet | `#4A1259` | `#F8F0FA` |
| **Sport** | `#65A830` vert | `#3D7A1E` | `#F7FBF2` |
| **Culture** | `#0891B2` cyan | `#004D5F` | `#EFF9FB` |
| **Family** | `#D97706` ambre | `#92400E` | `#FFFBEB` |
| **Food** | `#E11D48` rose | `#9F1239` | `#FFF1F2` |
| **Gaming** | `#6366F1` indigo | `#3730A3` | `#EEF2FF` |
| **Night** | `#7C3AED` violet fonce | `#4C2889` | `#F3EEFF` |

Chaque theme inclut : gradient toolbar, gradient chips, couleurs boutons, textes d'accueil personnalises.

---

## 5. Les 7 modes

### 5.1 Day - Concerts & Spectacles

**Donnees** : API Toulouse OpenDataSoft (temps reel) + evenements curates

| Categorie | Source | Affichage |
|-----------|--------|-----------|
| Cette Semaine | Agregation de toutes les categories | EventRowCard groupe par categorie |
| Concert | ConcertToulouseService (API) | EventRowCard |
| Festival | FestivalToulouseService (API) | EventRowCard |
| Opera | OperaToulouseService (API) | EventRowCard |
| DJ Set | DjsetToulouseService (API) | EventRowCard |
| Showcase | ShowcaseToulouseService (API) | EventRowCard |
| Spectacle | SpectacleToulouseService (API) | EventRowCard |

**Pipeline API** : Fetch API → Merge curates → Dedup par titre+date → Filtrer passes → Tri chronologique

**Cards** : EventRowCard avec pochette (image venue specifique ou categorie), titre, date, lieu, horaires, bouton Billetterie, coeur Like, partage.

### 5.2 Sport - Sport & evenements sportifs

**Donnees** : APIs ESPN (rugby), Football-Data.org, Supabase + evenements curates

| Categorie | Source |
|-----------|--------|
| Cette Semaine | Agregation |
| Rugby | ESPN API (Stade Toulousain, Colomiers) |
| Football | Football-Data.org (TFC) |
| Basketball | Supabase matches |
| Handball | Supabase matches (Fenix Toulouse) |
| Boxe | 8 evenements curates |
| Natation | 7 evenements curates |
| Course a pied | CommerceRepository (base locale) |
| Salle de Fitness | FitnessVenuesData (curate) |

**Cards** : MatchRowCard avec pochette equipe, score, date, lieu.

### 5.3 Culture - Culture & Arts

**Donnees** : API Toulouse OpenDataSoft + lieux curates statiques

| Categorie | Lieux curates | Affichage |
|-----------|--------------|-----------|
| Cette Semaine | MuseumEventsToulouseService (API) | EventRowCard |
| Theatre | 19 salles | TheatreVenueCard (groupe) |
| Danse | 20 ecoles/compagnies | DanceVenueCard (groupe) |
| Exposition | CommerceRepository | CommerceRowCard |
| Galerie d'art | GalleryVenuesData | CultureVenueCard |
| Monument historique | 19 monuments | MonumentVenueCard (3 groupes) |
| Visites guidees | GuidedToursToulouseService (API) | EventRowCard |

**Groupes Monuments** :
- Hotels particuliers (10)
- Urbanisme & vestiges historiques (5)
- Autres elements inscrits (4)

### 5.4 Family - En Famille

**Donnees** : Lieux curates statiques uniquement

| Categorie | Nb lieux | Groupes | Card |
|-----------|----------|---------|------|
| Cette Semaine | Agregation DB | - | CommerceRowCard |
| Parc d'attractions | 9 | - (liste plate) | CommerceRowCard |
| Aire de jeux | 10 | - (liste plate) | PlaygroundVenueCard |
| Parc animalier | 6 | 3 groupes | AnimalParkVenueCard |
| Cinema | 11 | 3 groupes | CinemaVenueCard |
| Bowling | 5 | 2 groupes | BowlingVenueCard |
| Laser game | 5 | - (liste plate) | LaserGameVenueCard |
| Escape game | 16 | 3 groupes | EscapeGameVenueCard |
| Aquarium | DB locale | - | CommerceRowCard |
| Restaurant familial | 5 | - (liste plate) | FamilyRestaurantVenueCard |

**Groupes Cinema** : Multiplexes (3), Cinemas independants & art (5), Autres salles (3)
**Groupes Escape Game** : Escape games a Toulouse (9), Jeux d'evasion (2), Proches de Toulouse (5)
**Groupes Parc animalier** : Zoo & safari (1), Fermes autour de Toulouse (4), Excursion journee (1)
**Groupes Bowling** : Bowls a Toulouse (4), Agglomeration (1)

### 5.5 Food - Food & lifestyle

**Donnees** : Lieux curates + CommerceRepository (DB locale)

| Categorie | Nb lieux | Groupes | Card |
|-----------|----------|---------|------|
| Cette Semaine | Agregation DB | - | CommerceRowCard |
| Restaurant | 10 | 4 groupes | RestaurantVenueCard |
| Sushi & japonais | DB locale | - | CommerceRowCard |
| Salon de the | DB locale | - | CommerceRowCard |
| Brunch | DB locale | - | CommerceRowCard |
| Spa & hammam | DB locale | - | CommerceRowCard |
| Yoga & meditation | DB locale | - | CommerceRowCard |

**Groupes Restaurant** : Experiences uniques (3), Ambiances insolites (3), Creativite culinaire (3), Concepts originaux (1)

### 5.6 Gaming - Gaming & pop culture

**Donnees** : CommerceRepository (DB locale via Overpass/OSM)

| Groupe | Sous-categories |
|--------|----------------|
| Jeux video | Salle d'arcade, Gaming cafe, VR & realite virtuelle |
| Jeux de societe & cartes | Bar a jeux, Boutique jeux, Escape game |
| Manga, comics & BD | Boutique manga, Comics & BD, Figurines & goodies |
| Evenements & conventions | Convention & salon, Tournoi e-sport, Cosplay |

### 5.7 Night - Nuit & sorties

**Donnees** : CommerceRepository (DB locale) + NightBarsData

| Groupe | Sous-categories |
|--------|----------------|
| Bars & vie nocturne | Bar de nuit, Club/Discotheque, Bar a cocktails, Bar a chicha, Pub |
| Commerces ouverts la nuit | Epicerie de nuit, SOS Apero, Tabac de nuit |
| Hebergement | Hotel |

---

## 6. Sources de donnees

### 6.1 APIs externes

| API | Usage | Endpoint |
|-----|-------|----------|
| **Toulouse OpenDataSoft** | Evenements culturels, concerts, festivals | `data.toulouse-metropole.fr/api/explore/v2.1/` |
| **INSEE SIRENE** | Registre des entreprises francaises | `api.insee.fr/` |
| **Overpass / OSM** | Points d'interet geographiques | `overpass-api.de/api/` |
| **Football-Data.org** | Matchs de football | `api.football-data.org/v4/` |
| **ESPN Sports** | Matchs de rugby | `site.api.espn.com/` |
| **Ticketmaster** | Billetterie evenements | `app.ticketmaster.com/discovery/v2/` |
| **Festik** | Billetterie festivals | `billetterie.festik.net/` |
| **OpenAgenda** | Evenements multi-villes | `openagenda.com/` |
| **Geo.gouv.fr** | Communes francaises | `geo.api.gouv.fr/communes` |
| **Supabase** | Backend (auth, matchs, evenements utilisateur) | Instance configuree |

### 6.2 Base de donnees locale (SQLite / Drift)

| Table | Champs cles | Usage |
|-------|------------|-------|
| **Commerces** | nom, categorie, ville, adresse, lat/lng, horaires, telephone, siteWeb, siret, source | Commerces et lieux locaux |
| **Categories** | nom, emoji, nafCodes, osmTags | Mapping categories vers codes NAF/OSM |
| **Villes** | nom, codePostal, codeInsee, lat/lng, timestamps sync | Villes indexees |

### 6.3 Donnees curates statiques

**154 lieux curates** repartis dans 14 fichiers de donnees :

| Fichier | Nb lieux |
|---------|----------|
| museum_venues_data.dart | 17 musees |
| theatre_venues_data.dart | 19 theatres |
| dance_venues_data.dart | 20 ecoles de danse |
| library_venues_data.dart | 20 bibliotheques |
| monument_venues_data.dart | 19 monuments |
| restaurant_venues_data.dart | 10 restaurants |
| escape_game_venues_data.dart | 16 escape games |
| cinema_venues_data.dart | 11 cinemas |
| playground_venues_data.dart | 10 aires de jeux |
| animal_park_venues_data.dart | 6 parcs animaliers |
| bowling_venues_data.dart | 5 bowlings |
| laser_game_venues_data.dart | 5 laser games |
| family_restaurant_venues_data.dart | 5 restaurants familiaux |
| park_venues_data.dart | 9 parcs d'attractions |

---

## 7. Composants UI principaux

### 7.1 Ecran d'accueil (HomeScreen)

```
+---------------------------------------+
| [Logo]  MaCity                    [i]  |  <- Toolbar gradient violet
|         Tous les evenements...         |
+---------------------------------------+
| [pin] Toulouse           [v]           |  <- Selecteur de ville
+---------------------------------------+
| ~~~ Banniere publicitaire defilante ~~~|  <- AdBannerMarquee
+---------------------------------------+
| Que faire aujourd'hui ?    [Ajouter]   |
+---------------------------------------+
| +-----------------------------------+ |
| | [image]         Concerts &        | |  <- 7 cartes mode
| |                 Spectacles    ->  | |     160px hauteur
| +-----------------------------------+ |     Image + overlay sombre
| +-----------------------------------+ |
| | [image]         Sport &           | |
| |                 evenements    ->  | |
| +-----------------------------------+ |
| ...                                    |
+---------------------------------------+
```

### 7.2 Ecran de mode (ModeShell + *Screen)

```
+---------------------------------------+
| [<]  Mode emoji + Label               |  <- ModeHeader
+---------------------------------------+
| [Day] [Sport] [Culture] [Family] ...  |  <- ModeChipBar (scroll horizontal)
+---------------------------------------+
| Subtitle du mode                       |
+---------------------------------------+
| +----------+ +----------+ +----------+|
| | [image]  | | [image]  | | [image]  ||  <- Grille 3 colonnes
| | Concert  | | Festival | | Opera    ||     DaySubcategoryCard
| |   (12)   | |   (5)    | |   (3)    ||     avec compteur
| +----------+ +----------+ +----------+|
| +----------+ +----------+ +----------+|
| | [image]  | | [image]  | | [image]  ||
| | DJ Set   | | Showcase | | Spectacle||
| +----------+ +----------+ +----------+|
+---------------------------------------+
```

### 7.3 Cards

**EventRowCard** (evenements API) :
```
+------------------------------------------+
| [Pochette  ]  Titre de l'evenement       |
| [110x      ]  12/02/2026                 |
| [image     ]  Lieu - Salle               |
| [+ overlay ]  19h30 - 23h00             |
| [GRATUIT   ]  [Billetterie] [heart] [share]|
+------------------------------------------+
```

**CommerceRowCard** (commerces DB) :
```
+------------------------------------------+
| [Photo     ]  Nom du commerce            |
| [115x      ]  Categorie                  |
| [+ badge   ]  Horaires                   |
| [Ouvert    ]  Adresse                    |
| [emoji     ]  [Map] [Tel] [Share]        |
+------------------------------------------+
```

**VenueCard curate** (bowling, cinema, escape game, etc.) :
```
+------------------------------------------+
| [Emoji     ]  Nom du lieu                |
| [90x       ]  Description (3 lignes max) |
| [fond mode ]  Horaires                   |
| [           ]  Adresse                    |
| [           ]  Tel (cliquable)           |
| [           ]  [Map] [Web] [Share]       |
+------------------------------------------+
```

### 7.4 Affichage groupe

Pour les categories avec groupes (cinema, bowling, escape game, monuments...) :

```
+------------------------------------------+
| emoji  Nom du groupe              (nb)   |  <- En-tete section
+------------------------------------------+
| [VenueCard 1]                            |
| [VenueCard 2]                            |
| [VenueCard 3]                            |
+------------------------------------------+
| emoji  Autre groupe               (nb)   |
+------------------------------------------+
| [VenueCard 4]                            |
| ...                                      |
+------------------------------------------+
```

---

## 8. Fonctionnalites transversales

### 8.1 Selection de ville
- Provider `selectedCityProvider` (defaut: "Toulouse")
- Bottom sheet avec recherche via geo.gouv.fr
- Impact sur toutes les requetes DB et API

### 8.2 Systeme de favoris
- `LikesRepository` avec persistence locale
- Coeur sur chaque EventRowCard
- Provider `likesProvider`

### 8.3 Partage
- Plugin `share_plus` sur chaque card
- Format : Nom + Adresse + Telephone + URL + "Decouvre sur MaCity"

### 8.4 Appel telephonique
- Lien `tel:` sur chaque numero de telephone
- Nettoyage automatique des espaces
- `url_launcher` avec verification `canLaunchUrl`

### 8.5 Liens externes
- Google Maps (lienMaps)
- Site web du lieu (websiteUrl)
- Billetterie (ticketUrl pour cinemas, parcs animaliers)

### 8.6 Ajout d'evenements utilisateur
- Bottom sheet `AddEventBottomSheet`
- Sauvegarde sur Supabase via `UserEventSupabaseService`

### 8.7 Authentification Instagram
- OAuth flow via `flutter_custom_tabs`
- Deep link callback via `app_links`
- URL scheme : `pulzapp://`

---

## 9. Configuration plateforme

### 9.1 Android
- **Min SDK** : 21
- **Target SDK** : 34
- **Package** : `com.pulzapp.toulouse`
- **Permissions** : INTERNET, ACCESS_NETWORK_STATE
- **Proguard** : Configure pour release

### 9.2 iOS
- **Deployment Target** : 13.0
- **Bundle ID** : `com.pulzapp.pulzApp`
- **URL Scheme** : `pulzapp`
- **LSApplicationQueriesSchemes** : https, http, tel
- **NSAppTransportSecurity** : AllowsArbitraryLoads (pour API HTTP)

---

## 10. Statistiques du projet

| Metrique | Valeur |
|----------|--------|
| Fichiers Dart | ~180 |
| Lignes de code | ~28 350 |
| Features | 12 modules |
| Modes utilisateur | 7 |
| Sous-categories totales | 56 |
| Lieux curates | 154 |
| APIs externes | 10 |
| Tables SQLite | 3 |
| Images assets | 100+ |
