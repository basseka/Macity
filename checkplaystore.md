# Audit conformite Google Play Store - Pulz App

Date : 2026-03-17

---

## [CRITIQUE] - Refus quasi-certain

### 1. Pas de politique de confidentialite

- **Probleme :** Aucune URL de privacy policy dans l'app ni dans le code. Aucune mention de "privacy", "RGPD", "CGU".
- **Pourquoi c'est bloquant :** Google Play **rejette systematiquement** les apps qui collectent des donnees (UUID device, FCM token, geolocalisation, login pro) sans privacy policy. Obligatoire depuis 2018.
- **Solution :** Creer une page web avec la politique de confidentialite, ajouter le lien dans la Play Console ET dans l'app (ecran preferences/a propos).

### 2. Mot de passe keystore `123456` en clair dans `key.properties`

- **Probleme :** `android/key.properties` contient `storePassword=123456` et `keyPassword=123456` en clair.
- **Pourquoi c'est bloquant :** Si ce fichier est commite dans git, n'importe qui peut signer des APK a votre nom. Google peut aussi considerer ca comme un probleme de securite. De plus le mot de passe `123456` est trivialement cassable.
- **Solution :** Changer le mot de passe du keystore, ajouter `key.properties` au `.gitignore`, utiliser des variables d'environnement CI/CD.

### 3. Tokens d'authentification stockes en clair (SharedPreferences)

- **Probleme :** `pro_session_service.dart` stocke `pro_access_token` et `pro_refresh_token` dans SharedPreferences (fichier XML en clair sur le device). Idem pour les credentials SIRENE dans `sirene_token_manager.dart`.
- **Pourquoi c'est bloquant :** Violation des regles Google Play sur la securite des donnees. Un malware ou un backup peut extraire ces tokens.
- **Solution :** Migrer vers `flutter_secure_storage` (Android Keystore / iOS Keychain).

### 4. Permission `ACCESS_FINE_LOCATION` sans justification in-app

- **Probleme :** L'app demande la localisation precise mais il n'y a pas de fonctionnalite visible qui le justifie clairement (pas de carte GPS en temps reel, pas de navigation).
- **Pourquoi c'est bloquant :** Google exige une justification visible pour `FINE_LOCATION`. Si le reviewer ne voit pas pourquoi, l'app est rejetee. Depuis 2023, il faut aussi remplir le formulaire de declaration de localisation dans la Play Console.
- **Solution :** Utiliser `ACCESS_COARSE_LOCATION` si la ville suffit. Si `FINE_LOCATION` est necessaire (carte des lieux), ajouter un ecran explicatif avant la demande de permission.

---

## [IMPORTANT] - Risque eleve de refus ou de suspension

### 5. Cles API hardcodees dans le code source

| Cle | Fichier | Risque |
|---|---|---|
| Football-data.org `568af3e5...` | `football_team_config.dart:20` | **ELEVE** - directement en dur |
| Ticketmaster `FZihyhGk...` | `api_constants.dart:55` | **MOYEN** - default d'un env var |
| Supabase anon key `eyJ...` | `supabase_config.dart:10` | **FAIBLE** - anon key publique par design |

- **Pourquoi c'est un probleme :** Les cles peuvent etre extraites du APK decompile. Google peut signaler l'app comme ayant des "credentials exposees".
- **Solution :** Passer toutes les cles via `--dart-define` au build, sans valeur par defaut dans le code. Pour football-data et Ticketmaster, deplacer les appels cote serveur (edge function Supabase).

### 6. `SCHEDULE_EXACT_ALARM` sans cas d'usage justifiable

- **Probleme :** Cette permission est restreinte depuis Android 14 (API 34). Google exige que l'app soit de type reveil/minuteur/calendrier pour l'utiliser.
- **Pourquoi c'est un probleme :** Une app de decouverte de ville n'entre pas dans les categories autorisees. Google peut rejeter.
- **Solution :** Migrer vers `AlarmManager.setAndAllowWhileIdle()` ou `WorkManager` pour les rappels de notification. Retirer `SCHEDULE_EXACT_ALARM` du manifest.

### 7. Logs debug en production

- **Probleme :** 60+ appels `debugPrint`/`print` dont certains loguent des tokens FCM, des payloads de notification, des URLs Supabase Storage, et les requetes/reponses HTTP (intercepteur Dio).
- **Pourquoi c'est un probleme :** En mode release, `debugPrint` ecrit quand meme dans logcat. Un malware peut lire ces logs sur les devices pre-Android 4.1.
- **Solution :** Wrapper tous les `debugPrint` dans `if (kDebugMode)` ou utiliser un package logger avec mode release desactive.

### 8. Formulaire de securite des donnees (Data Safety)

- **Probleme :** L'app collecte : UUID device, ville, preferences, tokens FCM, photos, email (pro login). Le formulaire Data Safety dans la Play Console doit refleter exactement ces collectes.
- **Pourquoi c'est un probleme :** Incoherence entre la declaration et le comportement reel = suspension.
- **Solution :** Remplir le formulaire Data Safety en declarant : identifiants device, localisation approximative, photos, preferences, informations de compte pro.

---

## [MINEUR] - Ameliorations recommandees

### 9. `google_fonts` charge les polices via le reseau

- **Probleme :** Aucune police dans `pubspec.yaml` sous `fonts:`. `google_fonts` fait un appel reseau au premier lancement.
- **Impact :** Texte par defaut affiche brievement (FOUT), consommation data, et echec si offline au premier lancement.
- **Solution :** Telecharger les fichiers `.ttf` de Poppins/Inter dans `assets/fonts/` et les declarer dans `pubspec.yaml`, ou utiliser `GoogleFonts.config.allowRuntimeFetching = false` apres avoir pre-bundle les polices.

### 10. Version de `intl` non pincee

- **Probleme :** `intl: any` dans pubspec.yaml.
- **Impact :** Build non reproductible, risque de casse avec une mise a jour automatique.
- **Solution :** Pincer a `intl: ^0.19.0` ou la version actuellement resolue.

### 11. `http://` en default pour BACKEND_URL

- **Probleme :** `api_constants.dart` a `http://10.0.2.2:3000/` et `http://localhost:3000/` comme valeurs par defaut.
- **Impact :** Si le build oublie de definir `BACKEND_URL`, les requetes partent en HTTP (bloquees par `usesCleartextTraffic=false` en release, mais erreur silencieuse).
- **Solution :** Mettre une URL HTTPS par defaut, ou faire planter l'app au demarrage si l'env var manque.

### 12. `receive_sharing_intent` possiblement abandonne

- **Probleme :** Ce package n'est plus tres maintenu et a des problemes connus avec Android 14+.
- **Solution :** Considerer la migration vers `receive_sharing_intent` v2 ou `share_handler`.

---

## Resume par priorite d'action

| # | Action | Effort | Impact |
|---|---|---|---|
| 1 | Ajouter privacy policy | 1h | Bloque la publication |
| 2 | Securiser keystore password | 15min | Securite critique |
| 3 | Migrer tokens vers flutter_secure_storage | 2h | Securite critique |
| 4 | Justifier ou retirer FINE_LOCATION | 30min | Bloque la publication |
| 6 | Retirer SCHEDULE_EXACT_ALARM | 1h | Risque de refus |
| 5 | Externaliser les API keys | 1h | Bonne pratique |
| 7 | Nettoyer les debugPrint | 30min | Securite |
| 8 | Remplir Data Safety form | 30min | Obligatoire |

---

## Details techniques

### Permissions Android declarees (AndroidManifest.xml)

- `INTERNET` - OK
- `RECEIVE_BOOT_COMPLETED` - OK (notifications)
- `SCHEDULE_EXACT_ALARM` - A retirer
- `ACCESS_FINE_LOCATION` - A justifier ou downgrader
- `ACCESS_COARSE_LOCATION` - OK

### SDK Versions

- `minSdkVersion` : 21 (Android 5.0)
- `targetSdkVersion` : 35 (Android 15)
- `compileSdkVersion` : 36

### Signing

- Keystore : `upload-keystore.jks`
- Alias : `pulz`
- ProGuard/R8 : active en release

### Donnees collectees (pour Data Safety form)

- UUID device (SharedPreferences)
- Ville / preferences utilisateur (Supabase)
- Token FCM (Firebase)
- Photos (upload Supabase Storage)
- Email / mot de passe (login pro - Supabase Auth)
- Localisation approximative (geolocator)
