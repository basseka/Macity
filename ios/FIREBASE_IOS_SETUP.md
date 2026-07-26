# Firebase iOS — à finaliser sur le Mac (Analytics + Push)

> Objectif : activer **Firebase Analytics** (MAU/DAU iOS) **et** débloquer le
> **push FCM iOS** (fin du bug "0 token iOS"). Les deux ont le même prérequis :
> le `GoogleService-Info.plist` + configuration native.

## État actuel (au 2026-07-26)
- Android : ✅ Analytics + push OK (`google-services.json`, plugin appliqué).
- iOS : ❌ **incomplet** — `GoogleService-Info.plist` absent, pods Firebase pas
  installés, `FirebaseApp.configure()` volontairement pas appelé (crash sinon).
  → iOS **invisible** côté Firebase (analytics ET push).
- `firebase_options.dart` a bien la config iOS (app `com.macity.app`).

## ⚠️ Ordre impératif (sinon crash au lancement / rejet App Store 2.1(a))
`FirebaseApp.configure()` **crashe si le `.plist` n'est pas présent**. Faire les
étapes DANS CET ORDRE.

## Étapes (sur le Mac)

### 1. Récupérer le bon `GoogleService-Info.plist`
- Console Firebase → projet **`pulz-app-5c24b`** → Paramètres du projet → tes apps.
- ⚠️ Il y a **DEUX apps iOS**. Prendre le plist de celle dont :
  - **Bundle ID = `com.macity.app`**
  - **appId = `1:935675945253:ios:25c021a36c463701613acc`**
  - (surtout PAS l'autre app iOS, sinon les stats partent au mauvais endroit)

### 2. Ajouter le plist au projet iOS
- Glisser `GoogleService-Info.plist` dans `ios/Runner/`.
- Dans Xcode : cocher la cible **Runner** ("Copy items if needed" + Target Membership = Runner).
- Vérifier : `grep -c GoogleService-Info.plist ios/Runner.xcodeproj/project.pbxproj` doit être > 0.

### 3. Dépendances
```bash
flutter pub get
cd ios && pod install && cd ..
```
(installe les pods Firebase, dont Analytics.)

### 4. Patch `ios/Runner/AppDelegate.swift`
**Remplacer** ce bloc au début de `didFinishLaunchingWithOptions` :
```swift
    // NE PAS appeler FirebaseApp.configure() ici : sans GoogleService-Info.plist,
    // cet appel natif crashe l'app au lancement (rejet App Store 2.1(a)).
    // Firebase est initialise cote Dart via DefaultFirebaseOptions (firebase_options.dart),
    // qui n'a pas besoin du fichier .plist.

    // Enregistrement APNs pour les push notifications
```
**par** :
```swift
    // Firebase configure nativement des le lancement (necessite le
    // GoogleService-Info.plist ajoute a la cible Runner). Demarre Analytics tot
    // ET rend Firebase pret immediatement -> plus de race sur l'APNs token,
    // debloque le token FCM iOS. Valeurs du plist == firebase_options.dart
    // (meme app com.macity.app) -> l'init Dart (main.dart) reutilise cette app.
    FirebaseApp.configure()

    // Enregistrement APNs pour les push notifications
```
Le reste du fichier ne change pas (APNs, AVAudioSession pour le son des stories,
cache `pendingApnsToken` qui reste par sécurité).

### 5. Build + test
```bash
flutter build ipa --release --build-name=X.X.X --build-number=N
```
- Vérifier dans **Firebase → Analytics → Realtime** qu'un device iOS apparaît.
- Vérifier qu'un **token FCM iOS** est bien enregistré (table `user_fcm_tokens`, platform=ios).
- Prérequis push iOS : **clé APNs .p8** uploadée dans Firebase → Cloud Messaging.

## Ce que ça débloque
- ✅ Analytics iOS (MAU/DAU iOS)
- ✅ Push FCM iOS

Voir aussi : `lib/core/services/analytics_service.dart`, `lib/main.dart`
(init Dart), et les notes projet Firebase / iOS push APNs.
