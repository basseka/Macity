# Universal Links iOS — à faire SUR LE MAC après `git pull`

Objectif : qu'un lien partagé `https://macity.app/event/{id}` ouvre l'app
directement sur iPhone (au lieu d'ouvrir Safari).

## Valeurs de référence
- Apple Team ID : `BG2AU3T74F`
- Bundle ID : `com.macity.app`
- appID Universal Links : `BG2AU3T74F.com.macity.app`
- App Store ID : `6778110272`
- Domaine : `macity.app` — chemins pris en charge : `/event/*`

---

## Étape A — Xcode (sur le Mac)

1. `git pull` (récupère l'entitlement + les fichiers ci-dessous).
2. Vérifier que `ios/Runner/Runner.entitlements` contient déjà :
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
     <string>applinks:macity.app</string>
   </array>
   ```
   (déjà committé — ne pas le retaper).
3. Ouvrir **`ios/Runner.xcworkspace`** dans Xcode (le `.xcworkspace`, pas le `.xcodeproj`).
4. Target **Runner → onglet "Signing & Capabilities"** :
   - Cliquer **+ Capability → "Associated Domains"**.
   - Ajouter le domaine : **`applinks:macity.app`**.
   - ⚠️ C'EST CETTE ÉTAPE qui rend l'entitlement réellement actif : Xcode écrit
     `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` dans le projet ET
     enregistre la capability dans le portail Apple Developer (nouveau provisioning).
   - ⚠️ Vérifier que le fichier entitlements pointé est bien `Runner/Runner.entitlements`.
     Si Xcode en crée un nouveau/doublon, fusionner pour garder `aps-environment` + `associated-domains`.
5. Terminal : `flutter pub get` puis `cd ios && pod install`.
6. Build + upload :
   - `flutter build ipa --release` (ou Xcode → Product → Archive)
   - Upload **TestFlight** puis **App Store** → publier une **nouvelle version**.
   (Les Universal Links ne s'activent que sur une version installée AVEC l'entitlement
   et le bon provisioning.)

## Étape B — Hébergement macity.app (PAS le Mac : FTP / cPanel LiteSpeed)

Déposer le fichier `litespeed_macity/.well-known/apple-app-site-association`
(présent dans ce repo) à l'URL :
```
https://macity.app/.well-known/apple-app-site-association
```
- **SANS extension** (pas `.json`)
- **Content-Type: application/json**, **HTTP 200**, **aucune redirection**
- Aujourd'hui cette URL renvoie 404 → tant qu'elle ne répond pas, iOS n'ouvrira pas l'app.

Voir `litespeed_macity/README.md` pour le détail.

## Étape C — Test (sur iPhone PHYSIQUE, pas le simulateur)

1. Installer la nouvelle version (TestFlight ou App Store).
2. Dans l'app **Notes** (ou un mail à soi-même), écrire un vrai lien :
   `https://macity.app/event/<un_id_event_reel>` et le **taper** (ne pas le coller dans Safari).
3. Attendu : l'app MaCity s'ouvre directement sur l'event.
4. Si ça échoue :
   - iOS récupère l'AASA via le CDN Apple à l'installation → désinstaller/réinstaller l'app.
   - Vérifier que le CDN Apple voit le fichier :
     `https://app-site-association.cdn-apple.com/a/v1/macity.app`
   - Vérifier qu'aucune redirection ne traîne sur `/.well-known/apple-app-site-association`.

## Rappel — fallback web (page LiteSpeed `/event/{id}`)
La page actuelle ne gère que `intent://` (Android). À compléter avec un bouton
**App Store** pour les iPhone sans l'app installée :
`https://apps.apple.com/app/macity-app/id6778110272`.
