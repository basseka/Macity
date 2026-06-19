# 📱 MEMO — Activer les notifications push iOS (à faire sur le Mac)

> Contexte : les push marchent sur Android mais **0 token iOS** n'était enregistré.
> Le **code est corrigé** (commit `4ea5d63` : fix race APNs ↔ init Firebase dans
> `AppDelegate.swift` + `fcm_service.dart`). Il reste la **config Apple/Firebase**
> ci-dessous, puis un rebuild sur iPhone physique.

**Infos à garder sous la main :**
- **Bundle ID** : `com.macity.app`
- **Apple Team ID** : `BG2AU3T74F`
- **Firebase sender ID** : `935675945253`

---

## (1) Clé APNs → Firebase  ⭐ bloquant n°1

### A. Créer la clé chez Apple
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Keys**
2. `+` (Create a key) → nom ex. `MaCity APNs`
3. Cocher **Apple Push Notifications service (APNs)** → Continue → Register
4. **Download** → fichier `AuthKey_XXXXXXXXXX.p8` (⚠️ téléchargeable **une seule fois**, à conserver)
5. **Noter le Key ID** (10 caractères, aussi dans le nom du fichier)

> Une clé `.p8` couvre **dev + prod** et marche pour toutes les apps (max 2 clés/compte).

### B. Uploader dans Firebase
1. https://console.firebase.google.com → projet (sender `935675945253`)
2. ⚙️ **Paramètres du projet** → onglet **Cloud Messaging**
3. Section **Apple app configuration** → app `com.macity.app`
4. **APNs Authentication Key** → **Upload** :
   - fichier `.p8`
   - **Key ID** (étape A.5)
   - **Team ID** = `BG2AU3T74F`
5. Enregistrer

> ⚠️ Si l'app `com.macity.app` n'existe pas encore dans Firebase → l'ajouter d'abord
> (Project settings → Vos applications → Ajouter une app → iOS).

---

## (2) Capability Push + provisioning
1. Apple Developer → **Identifiers** → `com.macity.app` → cocher **Push Notifications** → Save
2. Xcode → cible **Runner** → **Signing & Capabilities** → `+ Capability` → **Push Notifications**
3. « Automatically manage signing » coché → Xcode régénère le profil avec la capability

---

## (3) aps-environment = production pour l'App Store  ✅ FAIT (code)
- Split entitlements par config codé :
  - `Runner.entitlements` (`development`) → Debug + Profile
  - `Runner-Release.entitlements` (`production`) → Release (TestFlight/App Store)
  - `CODE_SIGN_ENTITLEMENTS` câblé dans les 3 configs du target Runner (était absent avant → le fichier entitlements n'était même pas appliqué).
- ⚠️ À valider dans Xcode : à l'ajout de la capability Push (point 2), vérifier que Xcode
  **ne recrée pas** un entitlements en doublon et ne décâble pas `CODE_SIGN_ENTITLEMENTS`.
  Comme les deux fichiers contiennent déjà `aps-environment`, le toggle doit juste cocher l'identifier.

---

## (4) Rebuild + test
1. `git pull` sur le Mac (récupère le fix `4ea5d63`)
2. `flutter pub get` puis `cd ios && pod install`
3. Build/Run sur un **iPhone PHYSIQUE** (le push ne marche PAS sur simulateur)
4. **Accepter** le pop-up de permission notifications

## (5) Vérifier que ça marche
- Une ligne doit apparaître dans Supabase `user_fcm_tokens` avec `platform = 'ios'`.
- Logs Xcode si échec :
  - `APNs token indisponible apres ~10s` → **clé APNs manquante** (point 1) ou capability (point 2)
  - `[APNs] echec enregistrement…` → **provisioning / entitlement** (points 2-3)
- Puis tester un envoi depuis **admin.html → 🔔 Notifications push**.

---

## Rappel backend (hors iPhone, à déployer côté Supabase)
Les fonctions push sont dans `appli/supabase/functions/` (hors dépôt) — à **redéployer** :
`broadcast-notification`, `send-promo-notifications`, `send-mairie-notification`,
`send-daily-digest`, `send-featured-digest`, `notify-chat-message`,
`notify-nearby-reported-event` (dédup tokens + CORS + ciblage broadcast).
