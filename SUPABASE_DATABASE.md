# MaCity - Architecture Supabase

> Ce document decrit comment l'application MaCity utilise Supabase comme backend cloud.

---

## 1. Configuration

### 1.1 Connexion

| Parametre | Valeur |
|-----------|--------|
| **URL Supabase** | `https://dpqxefmwjfvoysacwgef.supabase.co` |
| **API REST** | `https://dpqxefmwjfvoysacwgef.supabase.co/rest/v1/` |
| **Storage** | `https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/` |
| **Edge Functions** | `https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/` |
| **Authentification** | Anon Key (JWT) |

### 1.2 Fichiers de configuration dans l'app

| Fichier | Role |
|---------|------|
| `lib/core/config/supabase_config.dart` | URL, anon key, endpoints Edge Functions |
| `lib/core/constants/api_constants.dart` | URL REST PostgREST |
| `lib/core/network/supabase_interceptor.dart` | Intercepteur Dio (inject headers) |

### 1.3 Authentification des requetes

Toutes les requetes vers Supabase passent par un **intercepteur Dio** (`SupabaseInterceptor`) qui ajoute automatiquement :

```
Headers:
  apikey: <SUPABASE_ANON_KEY>
  Authorization: Bearer <SUPABASE_ANON_KEY>
```

Cela utilise le **Row Level Security (RLS)** de Supabase avec le role `anon`.

---

## 2. Tables PostgREST

### 2.1 Table `matchs` - Matchs sportifs

Stocke les matchs et evenements sportifs locaux.

#### Schema

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | `integer` (PK, auto) | Identifiant unique |
| `sport` | `text` | Type de sport (`rugby`, `football`, `basketball`, `handball`) |
| `competition` | `text` | Nom de la competition (ex: `Top 14`, `Ligue 1`) |
| `equipe_dom` | `text` | Equipe a domicile |
| `equipe_ext` | `text` | Equipe a l'exterieur |
| `date` | `text` | Date du match (format `YYYY-MM-DD`) |
| `heure` | `text` | Heure de debut (ex: `21:00`) |
| `lieu` | `text` | Nom du stade/salle |
| `ville` | `text` | Ville du match |
| `description` | `text` | Description complementaire |
| `score` | `text` | Score (vide si pas encore joue) |
| `gratuit` | `text` | `oui` / `non` |
| `url` | `text` | Lien billetterie |
| `source` | `text` | Source de la donnee |

#### Service : `SupabaseApiService`

**Fichier** : `lib/features/sport/data/supabase_api_service.dart`

**Requetes** :

```
GET /rest/v1/matchs?select=*
GET /rest/v1/matchs?select=*&sport=eq.rugby
GET /rest/v1/matchs?select=*&sport=eq.rugby&ville=eq.Toulouse
GET /rest/v1/matchs?select=*&and=(date.gte.2026-02-01,date.lt.2026-03-01)
```

**Filtres disponibles** :
- `sport` : filtre par type de sport (`eq.rugby`, `eq.football`, etc.)
- `ville` : filtre par ville (`eq.Toulouse`)
- `date` : filtre par plage de dates (`gte` / `lt`)

**Modele Dart** : `SupabaseMatch` (Freezed)

```dart
SupabaseMatch(
  id: 1,
  sport: 'rugby',
  competition: 'Top 14',
  equipe1: 'Stade Toulousain',    // JSON: equipe_dom
  equipe2: 'Racing 92',           // JSON: equipe_ext
  date: '2026-02-15',
  heure: '21:00',
  lieu: 'Stade Ernest-Wallon',
  ville: 'Toulouse',
  description: 'Journee 18',
  score: '',
  gratuit: 'non',
  billetterie: 'https://...',     // JSON: url
  source: 'admin',
)
```

---

### 2.2 Table `user_events` - Evenements utilisateur

Stocke les evenements crees par les utilisateurs de l'application.

#### Schema

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | `text` (PK) | UUID genere cote client |
| `titre` | `text` | Titre de l'evenement |
| `description` | `text` | Description |
| `categorie` | `text` | Categorie (`Concert`, `Festival`, `Spectacle`, etc.) |
| `rubrique` | `text` | Rubrique/mode d'origine |
| `date` | `text` | Date (format `YYYY-MM-DD`) |
| `heure` | `text` | Heure (ex: `20:30`) |
| `lieu_nom` | `text` | Nom du lieu |
| `lieu_adresse` | `text` | Adresse du lieu |
| `photo_url` | `text` | URL de la photo (Supabase Storage) |
| `ville` | `text` | Ville |
| `created_at` | `timestamptz` | Date de creation |

#### Service : `UserEventSupabaseService`

**Fichier** : `lib/features/day/data/user_event_supabase_service.dart`

**Operations CRUD** :

| Operation | Methode HTTP | Endpoint | Description |
|-----------|-------------|----------|-------------|
| **Lire tous** | `GET` | `/rest/v1/user_events?select=*&order=date.asc` | Tous les evenements tries par date |
| **Lire par ville** | `GET` | `/rest/v1/user_events?select=*&ville=eq.Toulouse&order=date.asc` | Filtrer par ville |
| **Creer** | `POST` | `/rest/v1/user_events` | Inserer un evenement (header `Prefer: return=minimal`) |
| **Supprimer par id** | `DELETE` | `/rest/v1/user_events?id=eq.<uuid>` | Supprimer un evenement |
| **Purger expires** | `DELETE` | `/rest/v1/user_events?date=lt.2026-02-11` | Supprimer les evenements passes |

**Modele Dart** : `UserEvent`

```dart
UserEvent(
  id: 'uuid-v4',
  titre: 'Concert rock',
  description: 'Super concert au Bikini',
  categorie: 'Concert',
  rubrique: 'day',
  date: '2026-03-15',
  heure: '20:30',
  lieuNom: 'Le Bikini',           // JSON: lieu_nom
  lieuAdresse: 'Ramonville',      // JSON: lieu_adresse
  photoUrl: 'https://...png',     // JSON: photo_url
  ville: 'Toulouse',
  createdAt: DateTime.now(),       // JSON: created_at
)
```

**Serialisation** : Le modele a deux formats :
- `toJson()` / `fromJson()` : camelCase pour le cache local (SharedPreferences)
- `toSupabaseJson()` / `fromSupabaseJson()` : snake_case pour PostgREST

**Conversion** : `UserEvent.toEvent()` convertit en `Event` unifie pour l'affichage dans les listes d'evenements.

---

## 3. Storage (Bucket)

### 3.1 Bucket `user-events`

Stocke les photos des evenements ajoutes par les utilisateurs.

#### Fonctionnement

1. L'utilisateur prend/selectionne une photo via `image_picker`
2. L'app uploade le fichier vers Supabase Storage
3. L'URL publique est stockee dans la table `user_events.photo_url`

#### Upload

```
POST /storage/v1/object/user-events/<filename>
Headers:
  Content-Type: image/jpeg (ou image/png, image/webp, image/gif)
  apikey: <ANON_KEY>
  Authorization: Bearer <ANON_KEY>
Body: bytes du fichier
```

**Nommage** : `<timestamp_ms>_<nom_fichier_original>`
Exemple : `1739285400000_photo.jpg`

#### URL publique

```
https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/user-events/<filename>
```

#### Content-types supportes

| Extension | Content-Type |
|-----------|-------------|
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.png` | `image/png` |
| `.gif` | `image/gif` |
| `.webp` | `image/webp` |

---

## 4. Edge Functions

### 4.1 `instagram-auth`

Edge Function serverless pour l'authentification Instagram OAuth.

**URL** : `https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/instagram-auth`

#### Action 1 : Obtenir l'URL d'authentification

```
GET /functions/v1/instagram-auth?action=get_auth_url
Headers:
  apikey: <ANON_KEY>
  Authorization: Bearer <ANON_KEY>

Response:
{
  "auth_url": "https://api.instagram.com/oauth/authorize?..."
}
```

L'app ouvre cette URL dans un navigateur externe. Instagram redirige vers `pulzapp://instagram-callback?code=<auth_code>`.

#### Action 2 : Echanger le code contre un token

```
POST /functions/v1/instagram-auth?action=exchange_code
Headers:
  apikey: <ANON_KEY>
  Authorization: Bearer <ANON_KEY>
  Content-Type: application/json
Body:
{
  "code": "<authorization_code>",
  "user_id": "<uuid>"
}

Response (succes):
{
  "success": true,
  "username": "nom_instagram"
}

Response (erreur):
{
  "success": false,
  "error": "message d'erreur"
}
```

**Flux complet** :
1. L'app appelle `get_auth_url` → recoit l'URL Instagram
2. L'utilisateur se connecte sur Instagram
3. Instagram redirige vers `pulzapp://instagram-callback?code=xxx`
4. L'app intercepte le deep link via `app_links`
5. L'app appelle `exchange_code` avec le code
6. L'Edge Function echange le code contre un token Instagram et retourne le username
7. Le username est sauvegarde localement (SharedPreferences)

---

## 5. Strategie de synchronisation

### 5.1 Evenements utilisateur (user_events)

L'app utilise une strategie **cloud-first avec fallback local** :

```
Demarrage de l'app
       |
       v
  Charger cache local (SharedPreferences)
       |
       v
  Afficher les donnees immediatement
       |
       v
  Synchroniser avec Supabase (en arriere-plan)
       |
       +-- Succes: Supprimer les expires sur le serveur
       |           Recuperer les evenements restants
       |           Mettre a jour le state + cache local
       |
       +-- Echec reseau: Garder le cache local tel quel
```

### 5.2 Ajout d'un evenement

```
Utilisateur clique "Ajouter"
       |
       v
  Upload photo vers Storage (si photo)
       |
       +-- Succes: Obtenir l'URL publique
       +-- Echec: Continuer sans URL photo
       |
       v
  Inserer dans Supabase (PostgREST)
       |
       +-- Succes: OK
       +-- Echec: Continuer quand meme
       |
       v
  Ajouter au state local + sauver SharedPreferences
```

### 5.3 Matchs sportifs (matchs)

Les matchs sont en **lecture seule** cote app. Ils sont geres par un admin via le dashboard Supabase ou un script.

```
App demande les matchs
       |
       v
  GET /rest/v1/matchs?sport=eq.rugby&date=gte.2026-02-11
       |
       +-- Succes: Afficher les matchs
       +-- Echec: Afficher un message d'erreur
```

Pas de cache local pour les matchs (donnees toujours fraiches).

---

## 6. Schema SQL a creer dans Supabase

### 6.1 Table `matchs`

```sql
CREATE TABLE matchs (
  id SERIAL PRIMARY KEY,
  sport TEXT NOT NULL DEFAULT '',
  competition TEXT NOT NULL DEFAULT '',
  equipe_dom TEXT NOT NULL DEFAULT '',
  equipe_ext TEXT NOT NULL DEFAULT '',
  date TEXT NOT NULL DEFAULT '',
  heure TEXT NOT NULL DEFAULT '',
  lieu TEXT NOT NULL DEFAULT '',
  ville TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  score TEXT NOT NULL DEFAULT '',
  gratuit TEXT NOT NULL DEFAULT 'non',
  url TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT ''
);

-- Index pour les requetes frequentes
CREATE INDEX idx_matchs_sport ON matchs(sport);
CREATE INDEX idx_matchs_ville ON matchs(ville);
CREATE INDEX idx_matchs_date ON matchs(date);

-- RLS : lecture publique
ALTER TABLE matchs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lecture publique matchs"
  ON matchs FOR SELECT
  USING (true);
```

### 6.2 Table `user_events`

```sql
CREATE TABLE user_events (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  categorie TEXT NOT NULL DEFAULT '',
  rubrique TEXT NOT NULL DEFAULT '',
  date TEXT NOT NULL DEFAULT '',
  heure TEXT NOT NULL DEFAULT '',
  lieu_nom TEXT NOT NULL DEFAULT '',
  lieu_adresse TEXT NOT NULL DEFAULT '',
  photo_url TEXT,
  ville TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour les requetes frequentes
CREATE INDEX idx_user_events_ville ON user_events(ville);
CREATE INDEX idx_user_events_date ON user_events(date);

-- RLS : lecture et ecriture publiques (anon)
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lecture publique user_events"
  ON user_events FOR SELECT
  USING (true);
CREATE POLICY "Insertion publique user_events"
  ON user_events FOR INSERT
  WITH CHECK (true);
CREATE POLICY "Suppression publique user_events"
  ON user_events FOR DELETE
  USING (true);
```

### 6.3 Bucket Storage `user-events`

```
-- A creer via le dashboard Supabase :
-- Storage > New Bucket
-- Nom : user-events
-- Public : true (pour servir les images sans auth)
```

---

## 7. Diagramme des flux

```
+------------------+          +------------------+
|   MaCity App     |          |    Supabase      |
+------------------+          +------------------+
|                  |          |                  |
|  SupabaseApi     |  REST    |  Table: matchs   |
|  Service     ----|--------->|  (lecture seule)  |
|                  |          |                  |
|  UserEvent       |  REST    |  Table:          |
|  SupabaseService |--------->|  user_events     |
|                  |  CRUD    |  (lecture/ecrit.) |
|                  |          |                  |
|  UserEvent       | Storage  |  Bucket:         |
|  SupabaseService |--------->|  user-events     |
|  (uploadPhoto)   |  POST    |  (photos)        |
|                  |          |                  |
|  Instagram       |  Edge    |  Function:       |
|  AuthService ----|--------->|  instagram-auth  |
|                  |  GET/POST|  (OAuth proxy)   |
|                  |          |                  |
+------------------+          +------------------+
        |
        | SharedPreferences
        v
+------------------+
|  Cache local     |
|  (fallback)      |
+------------------+
```

---

## 8. Resume des endpoints utilises

| Endpoint | Methode | Table/Ressource | Usage |
|----------|---------|-----------------|-------|
| `/rest/v1/matchs` | GET | matchs | Lire les matchs sportifs |
| `/rest/v1/user_events` | GET | user_events | Lire les evenements utilisateur |
| `/rest/v1/user_events` | POST | user_events | Creer un evenement |
| `/rest/v1/user_events` | DELETE | user_events | Supprimer un evenement |
| `/storage/v1/object/user-events/<file>` | POST | Bucket user-events | Upload photo |
| `/storage/v1/object/public/user-events/<file>` | GET | Bucket user-events | Lire photo (public) |
| `/functions/v1/instagram-auth` | GET | Edge Function | URL auth Instagram |
| `/functions/v1/instagram-auth` | POST | Edge Function | Echange code OAuth |
