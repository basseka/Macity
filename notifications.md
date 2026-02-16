# Fonctionnement des notifications dans PUL'Z

## Technologies utilisées

- **Firebase Cloud Messaging (FCM)** pour les push notifications (Android + iOS)
- **flutter_local_notifications** pour l'affichage en foreground
- **Supabase** (Edge Functions + PostgreSQL + pg_cron) pour le backend

---

## Déclenchement des notifications

Deux sources principales :

1. **Événements d'établissements** : quand un utilisateur "like" un établissement, des notifications sont automatiquement programmées pour ses futurs événements
2. **Événements utilisateur** : quand l'utilisateur crée un événement personnel, les rappels sont planifiés automatiquement

### 3 rappels sont programmés

- **15 jours** avant l'événement
- **1 jour** avant
- **1 heure** avant

---

## Architecture backend (file de notifications)

Le système utilise une **table `notification_queue`** avec des **triggers PostgreSQL** qui réagissent aux événements :

| Trigger | Quand |
|---|---|
| `fn_schedule_notifications()` | Création d'événement |
| `fn_reschedule_notifications()` | Modification d'événement |
| `fn_cancel_notifications()` | Suppression d'événement |
| `fn_like_schedule()` | Like d'un établissement |
| `fn_unlike_cancel()` | Unlike d'un établissement |
| `fn_schedule_user_event_notifications()` | Création d'événement utilisateur |
| `fn_cancel_user_event_notifications()` | Suppression d'événement utilisateur |

---

## Envoi des notifications

Un **cron job toutes les minutes** appelle l'Edge Function `send-notifications` qui :

1. **Récupère** jusqu'à 500 notifications en attente (avec verrouillage `FOR UPDATE SKIP LOCKED` pour éviter les doublons)
2. **Groupe** les notifications par utilisateur et par `batch_key` (anti-spam)
3. **Obtient** un token FCM via OAuth2 (JWT avec service account Firebase)
4. **Envoie** via l'API FCM v1 à chaque appareil de l'utilisateur
5. **Gère les erreurs** : supprime les tokens invalides (`UNREGISTERED`, `INVALID_ARGUMENT`), retente jusqu'à 3 fois

---

## Côté client (`fcm_service.dart`)

- **Au démarrage** : initialisation FCM, demande de permissions, enregistrement du token dans `user_fcm_tokens`
- **App en foreground** : affichage via `flutter_local_notifications` (canal `pulz_reminders`, haute importance)
- **App en background/fermée** : Firebase gère l'affichage automatiquement
- **Déconnexion** : le token FCM est supprimé de la table `user_fcm_tokens`

---

## Préférences utilisateur

Gérées via **Riverpod** (`notification_prefs_provider.dart`) et stockées dans la table `notification_preferences` :

- **Activation/désactivation globale** (`enabled`)
- **Choix individuel** pour chaque type de rappel :
  - `remind_15d` — rappel 15 jours avant
  - `remind_1d` — rappel 1 jour avant
  - `remind_1h` — rappel 1 heure avant
- Support futur pour les **heures silencieuses** (`quiet_hour_start` / `quiet_hour_end`)

---

## Gestion des tokens FCM

### Enregistrement (au démarrage de l'app)

1. `FcmService.init()` est appelé
2. Permissions demandées (iOS : alert, badge, sound)
3. Canal Android créé (`pulz_reminders`)
4. Token FCM récupéré et stocké dans `user_fcm_tokens` via upsert
5. Listener de rafraîchissement automatique du token

### Suppression (à la déconnexion)

- `FcmService.removeToken()` supprime le token de la base

---

## Maintenance automatique

| Tâche | Fréquence | Description |
|---|---|---|
| Envoi des notifications | Toutes les minutes | Traite jusqu'à 500 notifications en attente |
| Nettoyage | Tous les jours à 3h | Supprime les notifications de +30 jours |
| Retry | Toutes les 5 minutes | Relance les notifications échouées (< 3 tentatives) |

---

## Messages (en français)

| Type | Message |
|---|---|
| 15 jours avant | "Dans 15 jours — [date formatée]" |
| 1 jour avant | "Demain — [date formatée]" |
| 1 heure avant | "Dans 1 heure !" |
| Nouvel événement | "Nouvel événement le [date]" |
| Groupé | "[N] événements à venir" |

---

## Fichiers clés

### Client (Flutter)

| Fichier | Rôle |
|---|---|
| `lib/core/services/fcm_service.dart` | Intégration FCM principale |
| `lib/features/notifications/state/notification_prefs_provider.dart` | State management (Riverpod) |
| `lib/features/notifications/data/notification_prefs_service.dart` | Accès données préférences |
| `lib/main.dart` | Initialisation |

### Backend (Supabase)

| Fichier | Rôle |
|---|---|
| `supabase/functions/send-notifications/index.ts` | Edge Function d'envoi |
| `supabase/migrations/001_notification_system.sql` | Schéma et triggers principaux |
| `supabase/migrations/002_user_events_notifications.sql` | Notifications événements utilisateur |
| `supabase/migrations/20260213180000_notifications_15_days.sql` | Rappels 15 jours |
| `supabase/migrations/20260212230000_setup_cron_jobs.sql` | Configuration des cron jobs |

### Configuration

| Fichier | Rôle |
|---|---|
| `lib/firebase_options.dart` | Config projet Firebase |
| `android/app/src/main/AndroidManifest.xml` | Manifest Android (icône, canal, permissions) |
| `ios/Runner/AppDelegate.swift` | Setup iOS (APNs + Firebase) |
