import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Gere l'enregistrement du token FCM dans Supabase
/// et l'affichage des notifications en foreground.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static late final Dio _dio;
  static bool _initialized = false;
  static final List<StreamSubscription> _subscriptions = [];

  // --- Diagnostic push iOS (affiche un dialogue au demarrage si echec) ---
  // Capture l'etat de la chaine d'enregistrement pour pointer la cause exacte
  // sans avoir besoin de Console.app. A retirer une fois le push iOS valide.
  static AuthorizationStatus? lastPermission;
  static String? lastApnsToken;
  static String? lastFcmToken;
  static bool lastUpsertOk = false;
  static String? lastUpsertError;
  /// Complete quand la sequence d'enregistrement du token est terminee
  /// (succes ou echec) -> l'UI peut alors lire le diagnostic.
  static final Completer<void> diagnosticReady = Completer<void>();

  static String _short(String? s) =>
      (s == null || s.isEmpty) ? '∅' : '${s.substring(0, s.length.clamp(0, 14))}…';

  /// Rapport lisible de l'etat de la chaine push (permission/APNs/FCM/upsert).
  static String buildDiagnosticReport() {
    final b = StringBuffer()
      ..writeln('=== Diagnostic Push iOS ===')
      ..writeln('Plateforme : ${Platform.isIOS ? "iOS" : "Android"}')
      ..writeln('Mode release : $kReleaseMode')
      ..writeln('Permission : ${lastPermission ?? "?"}')
      ..writeln('APNs token : ${lastApnsToken == null ? "❌ NULL" : "✅ ${_short(lastApnsToken)}"}')
      ..writeln('FCM token : ${lastFcmToken == null ? "❌ NULL" : "✅ ${_short(lastFcmToken)}"}')
      ..writeln('Upsert Supabase : ${lastUpsertOk ? "✅ OK" : "❌ ${lastUpsertError ?? "non tente"}"}')
      ..writeln('Firebase appId : ${DefaultFirebaseOptions.ios.appId}')
      ..writeln('Bundle : ${DefaultFirebaseOptions.ios.iosBundleId}');
    return b.toString();
  }

  /// Callback appelé quand l'utilisateur tape sur une notification.
  /// La map contient les données FCM (type, universe, event_ids, etc.).
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  static const _androidChannel = AndroidNotificationChannel(
    'pulz_reminders',
    'Rappels PUL\'Z',
    description: 'Rappels pour vos événements',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    _dio.interceptors.add(SupabaseInterceptor());

    // Permissions (iOS + Android 13+ POST_NOTIFICATIONS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    lastPermission = settings.authorizationStatus;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Creer le canal Android
    await androidPlugin?.createNotificationChannel(_androidChannel);

    // Demander explicitement la permission notifications (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Initialiser flutter_local_notifications avec le tap handler
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Token initial.
    // iOS : getToken() renvoie null tant que l'APNs token n'est pas remonte a
    // Firebase (le device s'enregistre aupres d'Apple de maniere asynchrone).
    // On attend donc l'APNs token (jusqu'a ~10s) AVANT de demander le token FCM,
    // sinon le token n'est jamais recupere ni enregistre (bug : 0 token iOS).
    if (Platform.isIOS) {
      String? apns = await _messaging.getAPNSToken();
      for (var i = 0; apns == null && i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        apns = await _messaging.getAPNSToken();
      }
      lastApnsToken = apns;
      if (apns == null) {
        debugPrint('[FCM] APNs token indisponible apres ~10s '
            '(verifie la cle APNs dans Firebase + capability Push) — '
            'token FCM non recupere');
      }
    }

    String? token = await _messaging.getToken();
    // Retry court si null (absorbe une race APNs residuelle).
    for (var i = 0; token == null && i < 3; i++) {
      await Future.delayed(const Duration(seconds: 1));
      token = await _messaging.getToken();
    }
    lastFcmToken = token;
    if (token != null) await _upsertToken(token);
    if (!diagnosticReady.isCompleted) diagnosticReady.complete();

    // Refresh automatique
    _subscriptions.add(_messaging.onTokenRefresh.listen(_upsertToken));

    // Foreground messages → afficher via local notification
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_showForegroundNotification),
    );

    // Tap sur notification quand l'app est en background
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap),
    );

    // Tap sur notification quand l'app etait killed.
    // Choix produit : par defaut on ignore le deep-link et le splash laisse
    // arriver naturellement sur /home. EXCEPTION : type=chat_message — on
    // ouvre directement la discussion de la story concernee (UX critique
    // pour repondre a un commentaire).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final type = initialMessage.data['type'] as String?;
      if (type == 'chat_message' ||
          type == 'featured_digest' ||
          type == 'daily_digest') {
        // Delay un peu plus long que les autres handlers : le cold start
        // a besoin que le splash finisse + que le root navigator soit pret
        // avant de router. chat_message ouvre la discussion ; featured_digest
        // force l'accueil de maniere deterministe (ne pas dependre du
        // comportement de restauration d'activite de l'OEM).
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleNotificationTap(initialMessage);
        });
      } else {
        debugPrint(
          '[FCM] cold-start tap ignored (going to /home via splash): '
          '${initialMessage.data}',
        );
      }
    }

    // Annuler l'ancienne notification locale 18h (remplacée par daily digest server-side)
    await _localNotifications.cancel(_dailyReminderId);
  }

  /// Gère le tap sur une notification FCM (background/killed).
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] notification tap: ${message.data}');
    onNotificationTap?.call(message.data);
  }

  /// Gère le tap sur une notification locale (foreground).
  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] local notification tap: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      onNotificationTap?.call(data);
    } catch (e) {
      debugPrint('[FCM] payload parse error: $e');
    }
  }

  /// ID legacy de l'ancienne notification locale 18h (remplacee par daily
  /// digest server-side). Conserve pour l'annuler au prochain lancement des
  /// anciens builds qui l'avaient planifiee.
  static const _dailyReminderId = 88000;

  /// Affiche la notification même quand l'app est au premier plan.
  /// Encode les données FCM dans le payload pour récupération au tap.
  ///
  /// Sur Android, Firebase n'affiche PAS la notif systeme quand l'app est au
  /// premier plan, meme si le payload contient un champ notification. Il faut
  /// donc toujours afficher une local notification en foreground, en prenant
  /// les champs title/body du bloc notification OU a defaut de data.
  static Future<void> _showForegroundNotification(
      RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    debugPrint('[FCM] foreground data-only: $title');

    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF9C27B0),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> _upsertToken(String token) async {
    try {
      final userId = await UserIdentityService.getUserId();
      final deviceId = await _getDeviceId();

      await _dio.post(
        'user_fcm_tokens?on_conflict=user_id,device_id',
        data: {
          'user_id': userId,
          'token': token,
          'device_id': deviceId,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(
          headers: {
            'Prefer': 'resolution=merge-duplicates',
          },
        ),
      );
      lastUpsertOk = true;
      lastUpsertError = null;
      debugPrint('[FCM] token registered');
    } catch (e) {
      lastUpsertOk = false;
      lastUpsertError = e.toString();
      debugPrint('[FCM] token upsert failed: $e');
    }
  }

  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    return id;
  }

  /// Remet le compteur de badge a zero, localement ET cote serveur.
  /// A appeler quand l'utilisateur ouvre l'app (onResume, cold start).
  static Future<void> resetBadge() async {
    // 1. Clear du badge natif iOS/Android
    try {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      debugPrint('[FCM] AppBadgePlus reset failed: $e');
    }

    // 2. Reset du compteur cote serveur pour ce device
    try {
      final userId = await UserIdentityService.getUserId();
      final deviceId = await _getDeviceId();
      await _dio.patch(
        'user_fcm_tokens',
        queryParameters: {
          'user_id': 'eq.$userId',
          'device_id': 'eq.$deviceId',
        },
        data: {'badge_count': 0},
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );
    } catch (e) {
      debugPrint('[FCM] badge_count server reset failed: $e');
    }
  }

  /// Annuler tous les listeners FCM.
  static Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Supprimer le token (appeler au "logout" si necessaire).
  static Future<void> removeToken() async {
    try {
      final userId = await UserIdentityService.getUserId();
      final deviceId = await _getDeviceId();

      await _dio.delete(
        'user_fcm_tokens',
        queryParameters: {
          'user_id': 'eq.$userId',
          'device_id': 'eq.$deviceId',
        },
      );
    } catch (e) {
      debugPrint('[FCM] token removal failed: $e');
    }
  }
}
