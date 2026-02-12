# MaCity - Services API & Scrapers

> Ce document decrit comment l'application MaCity collecte ses donnees depuis differentes sources API, scrapers web et donnees curatees.

---

## 1. Architecture generale

### 1.1 Philosophie

L'application utilise une approche **multi-source avec fallback** : chaque categorie d'evenement est alimentee par un pipeline qui interroge plusieurs sources, fusionne les resultats, dedoublonne, filtre les evenements passes, et trie chronologiquement.

```
Source primaire (API officielle)
       |
       v
Source secondaire (API alternative)
       |
       v
Source tertiaire (scraper web)
       |
       v
Donnees curatees (fallback ultime)
       |
       v
Deduplication (titre normalise + date)
       |
       v
Filtrage (evenements passes)
       |
       v
Tri chronologique
       |
       v
Cache local (SharedPreferences, TTL 6h)
```

### 1.2 Client HTTP

Toutes les requetes HTTP passent par **Dio** configure via `DioClient` :

| Fichier | Role |
|---------|------|
| `lib/core/network/dio_client.dart` | Factory Dio avec timeouts |
| `lib/core/network/supabase_interceptor.dart` | Injecte headers Supabase (apikey + Bearer) |
| `lib/core/constants/api_constants.dart` | URLs, endpoints, cles API |

**Timeouts** : Connect 30s, Receive 30s

### 1.3 Modele unifie

Tous les evenements convergent vers le modele **`Event`** (Freezed) :

```dart
Event(
  identifiant, titre, dateDebut, dateFin, horaires,
  lieuNom, lieuAdresse, commune, categorie, type,
  description, descriptionLongue, photoPath,
  manifestationGratuite, tarifNormal, reservationUrl,
)
```

---

## 2. APIs externes

### 2.1 Toulouse OpenDataSoft (source principale evenements)

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://data.toulouse-metropole.fr/` |
| **Endpoint** | `api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records` |
| **Authentification** | Aucune (API publique) |

**Service** : `EventApiService` (`lib/features/day/data/event_api_service.dart`)

**Methodes** :
- `fetchEvents({String? where, int limit, int offset})` — Requete generique avec clause WHERE
- `fetchThisWeek()` — Evenements des 7 prochains jours
- `fetchByCategory(String category)` — Filtre par `type_de_manifestation` ou `categorie_de_la_manifestation`

**Clause WHERE (syntaxe SQL-like)** :
```
(lieu_nom LIKE "%Zenith%" OR lieu_nom LIKE "%Bikini%")
AND (type_de_manifestation LIKE "%Concert%")
AND date_debut >= "2026-02-11"
```

**Parametres de requete** :
```
where=<clause>
order_by=date_debut ASC
limit=100
offset=0
```

**Utilise par** : ConcertToulouseService, FestivalToulouseService, DjSetToulouseService, OperaToulouseService, ShowcaseToulouseService, SpectacleToulouseService, MuseumEventsToulouseService, GuidedToursToulouseService

---

### 2.2 Ticketmaster Discovery API v2

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://app.ticketmaster.com/` |
| **Endpoint** | `discovery/v2/events.json` |
| **Authentification** | API Key (query param `apikey`) |

**Service** : `TicketmasterApiService` (`lib/features/day/data/ticketmaster_api_service.dart`)

**Methode** : `fetchConcertsToulouse({int size = 50})`

**Parametres** :
```
apikey=<TICKETMASTER_API_KEY>
city=Toulouse
countryCode=FR
classificationName=Music
sort=date,asc
size=50
```

**Mapping** :
- Response : `_embedded.events[]`
- ID : `tm_<ticketmaster_id>`
- Image : triees par largeur, plus grande selectionnee
- Prix : `priceRanges[0].min - priceRanges[0].max`
- Lieu : `_embedded.venues[0].name` + `address.line1, postalCode city`

**Gestion d'erreur** : Retourne liste vide sur DioException

---

### 2.3 Festik (scraper JSON-LD)

| Parametre | Valeur |
|-----------|--------|
| **URL** | `https://billetterie.festik.net/` |
| **Type** | Scraper HTML + extraction JSON-LD |
| **Authentification** | Aucune |

**Service** : `FestikApiService` (`lib/features/day/data/festik_api_service.dart`)

**Methode** : `fetchToulouseEvents({String categorie = 'Festival'})`

**Pipeline de scraping** :
1. Requete GET avec header `Accept: text/html`
2. Extraction des blocs `<script type="application/ld+json">` via regex
3. Parse des objets schema.org `Event`
4. Filtrage par `addressLocality` dans la zone Toulouse (27 villes)

**Villes incluses** : toulouse, ramonville, balma, colomiers, blagnac, tournefeuille, labege, castanet-tolosan, muret, cugnaux, plaisance, saint-orens, l'union, aucamville, fonsorbes, castelginest, portet, aussonne, pin-balma, fenouillet, gratentour, launaguet, beauzelle, cornebarrieu, seilh, mondonville, pibrac

**Transformation** :
- Dates ISO 8601 → YYYY-MM-DD + HHhMM
- Adresse : `streetAddress, postalCode city`

**Utilise par** : ConcertToulouseService, FestivalToulouseService, SpectacleToulouseService

---

### 2.4 OpenAgenda (OpenDataSoft national)

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://public.opendatasoft.com/` |
| **Endpoint** | `api/explore/v2.1/catalog/datasets/evenements-publics-openagenda/records` |
| **Authentification** | Aucune |

**Service** : `OpenAgendaApiService` (`lib/features/day/data/open_agenda_api_service.dart`)

**Methode** : `fetchEvents({required String city, String? keyword, int limit, int offset})`

**Clause WHERE** :
```
location_city="Toulouse"
AND firstdate_begin >= "2026-02-11"
AND lastdate_end <= "2027-02-11"
AND (title_fr LIKE "%keyword%" OR keywords_fr LIKE "%keyword%")
```

**Plage de recherche** : 365 jours a partir d'aujourd'hui

---

### 2.5 MEETT (scraper HTML)

| Parametre | Valeur |
|-----------|--------|
| **URL** | `https://meett.fr/en/exhibitor/` |
| **Type** | Scraper HTML (parsing regex) |
| **Authentification** | User-Agent header |

**Service** : `MeettExhibitorService` (`lib/features/culture/data/meett_exhibitor_service.dart`)

**Methode** : `fetchUpcomingExhibitions()`

**Pipeline de scraping** :
1. Requete GET avec User-Agent
2. Extraction des blocs CSS `elementor-post`
3. Regex pour extraire :
   - Titre : `<h3 class="elementor-post__title"><a>TITRE</a></h3>`
   - Dates : pattern `DD-DD MMM YYYY` (mois EN/FR abreges)
   - Type : `Public` / `Professional`
   - Organisateur : texte apres `Organisee par`
   - Image : `<img src="https://meett.fr/wp-content/uploads/...">`

**Donnees curatees (fallback si scrape echoue)** : 8 salons
- art3f (Fev 12-15)
- Salon Vins & Terroirs (Mar 13-15)
- Salon Immobilier (Mar 13-15)
- OCC'YGENE (Mar 27-29)
- Foire Internationale de Toulouse (Avr 10-19)
- Camping-Car Salon (Mai 14-17)
- Vinomed (Jun 9-10)
- Salon Mineral & Gem (Jun 12-14)

**Lieu** : MEETT - Parc des Expositions, Concorde Avenue, 31840 Aussonne

---

### 2.6 ESPN Rugby

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://site.api.espn.com/` |
| **Endpoints** | `/apis/site/v2/sports/rugby/leagues/{leagueId}/events` |
|              | `/apis/site/v2/sports/rugby/teams/{teamId}/schedule` |
| **Authentification** | Aucune |

**Service** : `EspnRugbyApiService` (`lib/features/sport/data/espn_rugby_api_service.dart`)

**Methodes** :
- `fetchLeagueEvents({required int leagueId, String? dates})` — Matchs d'une ligue
- `fetchTeamEvents({required int teamId})` — Calendrier d'une equipe

---

### 2.7 Football Data API

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://api.football-data.org/` |
| **Endpoint** | `v4/teams/{teamId}/matches` |
| **Authentification** | Header `X-Auth-Token` |

**Service** : `FootballApiService` (`lib/features/sport/data/football_api_service.dart`)

**Methode** : `fetchTeamMatches({required int teamId, String? status, String? dateFrom, String? dateTo, int limit = 10})`

**Parametres** :
```
status=SCHEDULED
dateFrom=2026-02-11
dateTo=2026-06-30
limit=10
```

---

### 2.8 Geo.gouv.fr (communes)

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://geo.api.gouv.fr/` |
| **Endpoint** | `communes` |
| **Authentification** | Aucune |

**Service** : `CityApiService` (`lib/features/city/data/city_api_service.dart`)

**Methode** : `searchCommunes(String query)`

**Parametres** :
```
nom=Toulouse
fields=nom,code,codesPostaux,codeDepartement,codeRegion,population
boost=population
limit=10
```

---

### 2.9 SIRENE (INSEE — registre des entreprises)

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://api.insee.fr/` |
| **Endpoint** | `entreprises/sirene/V3.11/siret` |
| **Token URL** | `https://api.insee.fr/token` |
| **Authentification** | OAuth2 Client Credentials |

**Services** :
- `SireneApiService` (`lib/features/commerce/data/sirene_api_service.dart`)
- `SireneTokenManager` (`lib/features/commerce/data/sirene_token_manager.dart`)

**Flux OAuth2** :
1. Encode `consumerKey:consumerSecret` en base64
2. POST vers `/token` avec `grant_type=client_credentials`
3. Recoit `access_token` + `expires_in` (secondes)
4. Cache le token (SharedPreferences) jusqu'a expiration - 1 minute
5. Toutes les requetes SIRENE utilisent `Authorization: Bearer <token>`

**Methode** : `searchEtablissements({required String query, int limit, int offset})`

---

### 2.10 Overpass (OpenStreetMap)

| Parametre | Valeur |
|-----------|--------|
| **URL primaire** | `https://overpass-api.de/api/` |
| **URL fallback** | `https://overpass.kumi.systems/api/` |
| **Endpoint** | `interpreter` |
| **Authentification** | Aucune |

**Services** :
- `OverpassApiService` (`lib/features/commerce/data/overpass_api_service.dart`)
- `OverpassQueryBuilder` (`lib/features/commerce/data/overpass_query_builder.dart`)

**Methode** : `query(String overpassQl)` — POST avec `data=$overpassQl` (form-urlencoded)

**Fallback automatique** : Si le serveur primaire echoue (429/timeout), bascule vers `kumi.systems`

**Construction des requetes** :

Exemple pour "Bar" :
```
[out:json][timeout:25];
(
  node["amenity"="bar"](around:5000,43.6047,1.4442);
  way["amenity"="bar"](around:5000,43.6047,1.4442);
);
out center tags;
```

**Categories supportees** (40+) :

| Mode | Categories |
|------|-----------|
| Night | Bar, Bar de nuit, Discotheque, Bar a cocktails, Bar a chicha, Pub, Epicerie de nuit, Superette 24h, Station-service, Tabac de nuit, Hotel |
| Family | Parc d'attractions, Aire de jeux, Parc animalier, Cinema, Bowling, Laser game, Escape game, Musee, Bibliotheque, Aquarium, Restaurant familial, Fast-food, Glacier |
| Day | Concert, Festival, Theatre, Opera, Visites guidees, Animations culturelles |
| Sport | Rugby, Football, Basketball, Handball, Autres sports |

**Resolution de photos** (priorite) :
1. Tag `image` direct (URL validee)
2. Tag `wikimedia_commons` → `https://commons.wikimedia.org/wiki/Special:FilePath/{filename}?width=400`
3. Tags `image:0`, `image:1` (variantes numerotees)

---

### 2.11 Backend local (API REST optionnelle)

| Parametre | Valeur |
|-----------|--------|
| **URL Android** | `http://10.0.2.2:3000/` |
| **URL iOS** | `http://localhost:3000/` |
| **Authentification** | Aucune |

**Service** : `BackendApiService` (`lib/features/commerce/data/backend_api_service.dart`)

**Condition** : Desactive si l'URL contient `10.0.2.2`, `localhost` ou `127.0.0.1` (pas de backend reel configure)

**Endpoints** :

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | `api/commerces?lat=&lon=&radius=&query=` | Commerces par localisation |
| GET | `api/commerces?ville=&query=` | Commerces par ville |
| GET | `api/commerces/sync?since=<timestamp>` | Sync incrementale |
| POST | `api/commerces` | Ajouter un commerce |
| PUT | `api/commerces/:id` | Modifier un commerce |
| GET | `api/categories` | Liste des categories |
| GET | `api/villes` | Liste des villes |

---

## 3. Services agreges (pipelines multi-source)

### 3.1 ConcertToulouseService

**Fichier** : `lib/features/day/data/concert_toulouse_service.dart`

**Pipeline** :
```
1. Cache valide (6h) ? → retour immediat
2. Ticketmaster Discovery API (source primaire)
3. OpenDataSoft Toulouse (fallback)
4. Festik scraper (billetterie)
5. Donnees curatees (~50 concerts)
6. Deduplication (titre normalise + date)
7. Filtrage des passes
8. Tri chronologique
9. Sauvegarde en cache
```

**Salles ciblees (clause WHERE)** : Zenith, Metronum, Bikini, Halle aux Grains, Saint-Pierre-des-Cuisines, Nougaro, Taquin, Rex, Interference, Chapelle, Palais Consulaire, Carmelites

**Filtres type** : Concert, Musique

**Donnees curatees** : ~50 concerts provenant de 5 sources :

| Source | Nombre | Exemples |
|--------|--------|----------|
| Zenith Toulouse Metropole | ~19 | Goldmen, Ultra Vomit, Mika, Lara Fabian, Santa |
| Le Metronum | ~12 | Cryptopsy, Flora Fishbach, Baboucan, Ajar, Marguerite |
| Le Bikini | ~7 | Mayhem, Boulevard des Airs, Ofenbach, Myd |
| Candlelight by Fever | ~12 | Einaudi, Mozart/Chopin, Pink Floyd, ABBA, Queen, Hisaishi |
| Casino Barriere | ~6 | Jimmy Sax, Legende Balavoine, Gregoire, Laurent Voulzy |

**Deduplication** : `normalize(titre).toLowerCase().replaceAll(non-alphanum, '') + | + dateDebut`

---

### 3.2 FestivalToulouseService

**Fichier** : `lib/features/day/data/festival_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Festik scraper
3. Donnees curatees (2 festivals)
4. Deduplication + filtrage + tri
```

**Filtres type** : Festival

---

### 3.3 SpectacleToulouseService

**Fichier** : `lib/features/day/data/spectacle_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Festik scraper
3. Donnees curatees (~35 spectacles Casino Barriere)
4. Deduplication + filtrage + tri
5. Exclusion des evenements "theatre" (categorie separee)
```

**Filtres type** : Spectacle, Humour, Cirque, Danse, Magie

**Exclusion** : Evenements contenant "theatre" dans titre/categorie/lieu

**Donnees curatees** : ~35 spectacles au Casino Barriere Toulouse (Fev-Avr 2026)
- Constance - Inconstance, Time for Love, Messmer - 13Hz, etc.

---

### 3.4 DjSetToulouseService

**Fichier** : `lib/features/day/data/djset_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Donnees curatees (vide actuellement)
3. Deduplication + filtrage + tri
```

**Salles** : Bikini, Rex, Connexion Live, Ramier, Warehouse, Petit London, Zig Zag, Purple, Mouette, Usine, Metronum

**Filtres type** : DJ, electro, techno, house

---

### 3.5 OperaToulouseService

**Fichier** : `lib/features/day/data/opera_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Donnees curatees (vide actuellement)
3. Deduplication + filtrage + tri
```

**Filtres type** : Opera, Lyrique

---

### 3.6 ShowcaseToulouseService

**Fichier** : `lib/features/day/data/showcase_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Donnees curatees (vide actuellement)
3. Deduplication + filtrage + tri
```

**Salles** : Metronum, Connexion Live, Taquin, Petit London, Bikini, Rex, Nougaro, Interference

**Filtres type** : Showcase, live, acoustique

---

### 3.7 MuseumEventsToulouseService

**Fichier** : `lib/features/culture/data/museum_events_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Donnees curatees (9 expositions majeures)
3. Deduplication + filtrage + tri
```

**Musees (17)** : Augustins, Abattoirs, Bemberg, Paul-Dupuy, Saint-Raymond, Vieux Toulouse, Histoire de la Medecine, Resistance, Georges Labit, Museum de Toulouse, Jardins du Museum, Cite de l'Espace, Aeroscopia, Envol des Pionniers, Halle de la Machine, Espace Patrimoine, Chateau d'Eau

**Filtres type** : Exposition, Visite, Atelier, Vernissage, Animation

**Donnees curatees** : 9 expositions majeures

| Exposition | Lieu | Dates | Tarif |
|-----------|------|-------|-------|
| Picasso et l'Exil - Guernica | Les Abattoirs | Fev 15 - Jun 15 | 10€ |
| Lune: Episode II | Cite de l'Espace | Fev 1 - Nov 30 | 25-27€ |
| Biodiversite, Tous Vivants | Museum de Toulouse | Fev 20 - Sep 30 | 5-7€ |
| + 6 autres | ... | ... | ... |

---

### 3.8 GuidedToursToulouseService

**Fichier** : `lib/features/culture/data/guided_tours_toulouse_service.dart`

**Pipeline** :
```
1. OpenDataSoft Toulouse
2. Donnees curatees (10 visites guidees)
3. Deduplication + filtrage + tri
```

**Donnees curatees** : 10 visites

| Visite | Lieu | Horaires | Tarif |
|--------|------|----------|-------|
| Visite guidee du Capitole | Place du Capitole | Sam-Dim 10h30/14h30 | Gratuit |
| Basilique Saint-Sernin | Place Saint-Sernin | Mar-Sam 14h30 | 6€ |
| Couvent des Jacobins | Place des Jacobins | Mer-Dim 15h | 5€ |
| Canal du Midi balade | Port Saint-Sauveur | Sam 10h | Gratuit |
| Visite nocturne | Capitole | Ven 21h30 | 12€ |
| Croisiere sur la Garonne | Quai de la Daurade | Sam-Dim 15h | 14€ |
| Cite de l'Espace | Cite de l'Espace | Tous les jours | 25-27€ |
| + 3 autres | ... | ... | ... |

---

## 4. Cache et stockage

### 4.1 ConcertCacheService

**Fichier** : `lib/features/day/data/concert_cache_service.dart`

| Parametre | Valeur |
|-----------|--------|
| **Stockage** | SharedPreferences |
| **TTL** | 6 heures |
| **Cle donnees** | `concert_cache_data` |
| **Cle timestamp** | `concert_cache_timestamp` |

**Methodes** :
- `save(List<Event>)` — Serialise en JSON + timestamp
- `load()` — Retourne les evenements si cache valide
- `isValid()` — Verifie age < 6h
- `clear()` — Supprime le cache

**Note** : Le champ `photoPath` est preserve manuellement (exclu de @JsonKey)

---

### 4.2 OSM Enricher (cache 7 jours)

**Fichier** : `lib/features/commerce/data/osm_enricher.dart`

| Parametre | Valeur |
|-----------|--------|
| **Stockage** | Drift ORM (SQLite) |
| **TTL** | 7 jours par ville/categorie |
| **Bounding box** | +-0.05 degres (~5km) |

**Pipeline d'enrichissement** :
```
Pour chaque categorie avec osmTags :
  1. Verifier cache 7 jours → skip si recent
  2. Requete Overpass (bbox autour de la ville)
  3. Pour chaque element OSM :
     a. Match par nom (normalise, substring) dans la categorie
     b. Match par proximite (< 50m, Haversine)
     c. Si match : mettre a jour le commerce existant
     d. Sinon : creer un nouveau commerce
  4. Marquer source='osm' + lastUpdated
```

**Matching** :
- **Textuel** : Normalisation (minuscules, suppression non-alphanum), recherche substring
- **Spatial** : Distance Haversine, seuil 50 metres

**Champs extraits d'OSM** : name, addr:housenumber, addr:street, addr:postcode, addr:city, phone, contact:phone, website, contact:website, opening_hours, image, wikimedia_commons

---

## 5. Utilitaires de mapping

### 5.1 NafCategoryMapper

**Fichier** : `lib/features/commerce/data/naf_category_mapper.dart`

Convertit les codes NAF (Nomenclature d'Activites Francaise — INSEE) en categories locales.

**Strategie** :
1. Match exact du code complet (ex: `10.71C`)
2. Match par prefixe 5 caracteres (ex: `10.71`)

**Categories mappees (15)** :

| Categorie | Codes NAF |
|-----------|-----------|
| Boulangerie | 10.71C, 10.71D |
| Pharmacie | 47.73Z |
| Restaurant | 56.10A |
| Cafe | 56.30Z |
| Coiffeur | 96.02A, 96.02B |
| Fleuriste | 47.76Z |
| Epicerie | 47.11F, 47.29Z |
| Supermarche | 47.11A-D |
| Librairie | 47.61Z |
| Boucherie | 47.22Z |
| Poissonnerie | 47.23Z |
| Banque | 64.19Z |
| Pressing | 96.01A, 96.01B |
| Opticien | 47.78A |
| Veterinaire | 75.00Z |

### 5.2 OverpassQueryBuilder

**Fichier** : `lib/features/commerce/data/overpass_query_builder.dart`

Genere des requetes Overpass QL parametrees par categorie, coordonnees GPS et rayon.

**Methodes** :
- `buildQuery(String category, double lat, double lon, int radiusMeters)` → String Overpass QL
- `buildQueryFromOsmTags(String osmTags, double lat, double lon, int radiusMeters)` → String
- `buildAddress(Map<String, dynamic> tags)` → String adresse
- `resolvePhotoUrl(Map<String, dynamic> tags)` → String? URL photo

---

## 6. Services Supabase

### 6.1 SupabaseApiService (matchs sportifs)

**Fichier** : `lib/features/sport/data/supabase_api_service.dart`

| Parametre | Valeur |
|-----------|--------|
| **Base URL** | `https://dpqxefmwjfvoysacwgef.supabase.co/rest/v1/` |
| **Table** | `matchs` |
| **Authentification** | SupabaseInterceptor (anon key) |

**Methode** : `fetchMatches({String? sport, String? ville, String? dateGte, String? dateLt})`

**Filtres PostgREST** :
```
select=*
sport=eq.rugby
ville=eq.Toulouse
and=(date.gte.2026-02-01,date.lt.2026-03-01)
```

### 6.2 UserEventSupabaseService (evenements utilisateur)

**Fichier** : `lib/features/day/data/user_event_supabase_service.dart`

| Composant | URL |
|-----------|-----|
| **PostgREST** | `https://dpqxefmwjfvoysacwgef.supabase.co/rest/v1/` |
| **Storage** | `https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/` |
| **Table** | `user_events` |
| **Bucket** | `user-events` |

**Operations** :

| Methode | Action | Endpoint |
|---------|--------|----------|
| `uploadPhoto(localPath)` | Upload photo → URL publique | POST `object/user-events/<filename>` |
| `insertEvent(event)` | Creer evenement | POST `user_events` |
| `fetchEvents()` | Lire tous | GET `user_events?select=*&order=date.asc` |
| `fetchEventsByCity(ville)` | Lire par ville | GET `user_events?ville=eq.<ville>` |
| `deleteEvent(id)` | Supprimer par ID | DELETE `user_events?id=eq.<id>` |
| `deleteExpiredEvents()` | Purger expires | DELETE `user_events?date=lt.<today>` |

---

## 7. Diagramme des sources par mode

```
+──────────────────────────────────────────────────────────────────+
│                        MODE DAY                                   │
+──────────────────────────────────────────────────────────────────+
│                                                                   │
│  Concert ─────┬─ Ticketmaster API                                │
│               ├─ OpenDataSoft Toulouse                           │
│               ├─ Festik scraper                                  │
│               └─ Curates (~50 concerts)                          │
│                                                                   │
│  Festival ────┬─ OpenDataSoft Toulouse                           │
│               ├─ Festik scraper                                  │
│               └─ Curates (2 festivals)                           │
│                                                                   │
│  Spectacle ───┬─ OpenDataSoft Toulouse                           │
│               ├─ Festik scraper                                  │
│               └─ Curates (~35 Casino Barriere)                   │
│                                                                   │
│  DJ Set ──────┬─ OpenDataSoft Toulouse                           │
│               └─ Curates (vide)                                  │
│                                                                   │
│  Opera ───────┬─ OpenDataSoft Toulouse                           │
│               └─ Curates (vide)                                  │
│                                                                   │
│  Showcase ────┬─ OpenDataSoft Toulouse                           │
│               └─ Curates (vide)                                  │
│                                                                   │
│  User Events ── Supabase (table user_events)                     │
│                                                                   │
+──────────────────────────────────────────────────────────────────+

+──────────────────────────────────────────────────────────────────+
│                      MODE CULTURE                                 │
+──────────────────────────────────────────────────────────────────+
│                                                                   │
│  Musees ──────┬─ OpenDataSoft Toulouse                           │
│               └─ Curates (9 expositions)                         │
│                                                                   │
│  Visites ─────┬─ OpenDataSoft Toulouse                           │
│               └─ Curates (10 visites)                            │
│                                                                   │
│  Salons ──────┬─ MEETT scraper HTML                              │
│               └─ Curates (8 salons)                              │
│                                                                   │
│  Monuments ──── Donnees curatees statiques                       │
│  Theatres ───── Donnees curatees statiques                       │
│                                                                   │
+──────────────────────────────────────────────────────────────────+

+──────────────────────────────────────────────────────────────────+
│                       MODE SPORT                                  │
+──────────────────────────────────────────────────────────────────+
│                                                                   │
│  Rugby ──────── ESPN API + Supabase (table matchs)               │
│  Football ───── Football Data API + Supabase                     │
│                                                                   │
+──────────────────────────────────────────────────────────────────+

+──────────────────────────────────────────────────────────────────+
│                    MODES COMMERCES                                 │
│              (Night, Food, Family, Gaming)                        │
+──────────────────────────────────────────────────────────────────+
│                                                                   │
│  Commerces ───┬─ Overpass API (OpenStreetMap)                    │
│               ├─ SIRENE API (INSEE)                              │
│               ├─ Backend API (optionnel)                         │
│               └─ Drift SQLite (cache local)                      │
│                                                                   │
│  Enrichissement OSM :                                            │
│    Overpass → match nom/proximite → update Drift DB              │
│                                                                   │
│  Lieux curates :                                                 │
│    Bowling, Laser Game, Escape Game, Restaurants,                │
│    Aire de jeux, Restaurant familial                             │
│    → Donnees statiques (pas d'API)                               │
│                                                                   │
+──────────────────────────────────────────────────────────────────+

+──────────────────────────────────────────────────────────────────+
│                       VILLES                                      │
+──────────────────────────────────────────────────────────────────+
│                                                                   │
│  Recherche ──── geo.api.gouv.fr (communes)                       │
│                                                                   │
+──────────────────────────────────────────────────────────────────+
```

---

## 8. Resume des endpoints

| Service | API | URL | Auth |
|---------|-----|-----|------|
| EventApiService | OpenDataSoft Toulouse | `data.toulouse-metropole.fr/api/explore/v2.1/...` | Aucune |
| TicketmasterApiService | Ticketmaster Discovery v2 | `app.ticketmaster.com/discovery/v2/events.json` | API Key |
| FestikApiService | Festik (scraper) | `billetterie.festik.net/` | Aucune |
| OpenAgendaApiService | OpenDataSoft national | `public.opendatasoft.com/api/explore/v2.1/...` | Aucune |
| MeettExhibitorService | MEETT (scraper) | `meett.fr/en/exhibitor/` | User-Agent |
| EspnRugbyApiService | ESPN | `site.api.espn.com/apis/site/v2/sports/rugby/...` | Aucune |
| FootballApiService | football-data.org | `api.football-data.org/v4/teams/.../matches` | X-Auth-Token |
| CityApiService | Geo.gouv.fr | `geo.api.gouv.fr/communes` | Aucune |
| SireneApiService | INSEE SIRENE | `api.insee.fr/entreprises/sirene/V3.11/siret` | OAuth2 Bearer |
| OverpassApiService | OpenStreetMap | `overpass-api.de/api/interpreter` | Aucune |
| SupabaseApiService | Supabase PostgREST | `dpqxefmwjfvoysacwgef.supabase.co/rest/v1/matchs` | Anon Key |
| UserEventSupabaseService | Supabase PostgREST + Storage | `dpqxefmwjfvoysacwgef.supabase.co/rest/v1/user_events` | Anon Key |
| BackendApiService | Backend local | `10.0.2.2:3000/api/commerces` | Aucune |

---

## 9. Strategies de resilience

| Strategie | Services concernes |
|-----------|-------------------|
| **Cache local (6h)** | ConcertToulouseService |
| **Cache Drift (7j)** | OsmEnricher (par ville/categorie) |
| **Cache token OAuth2** | SireneTokenManager |
| **Serveur fallback** | OverpassApiService (primaire → kumi.systems) |
| **Multi-source sequentiel** | Concert, Festival, Spectacle (Ticketmaster → ODS → Festik → Curate) |
| **Donnees curatees** | Tous les services *ToulouseService + MEETT + visites + musees |
| **Catch silencieux** | Chaque source echoue independamment, le pipeline continue |
| **Backend optionnel** | BackendApiService desactive si pas de serveur reel |
