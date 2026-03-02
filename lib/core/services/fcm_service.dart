import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

/// Gere l'enregistrement du token FCM dans Supabase
/// et l'affichage des notifications en foreground.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static late final Dio _dio;
  static bool _initialized = false;

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
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Creer le canal Android
    await androidPlugin?.createNotificationChannel(_androidChannel);

    // Demander explicitement la permission notifications (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Demander la permission alarmes exactes (Android 12+)
    await androidPlugin?.requestExactAlarmsPermission();

    // Initialiser flutter_local_notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Token initial
    final token = await _messaging.getToken();
    if (token != null) await _upsertToken(token);

    // Refresh automatique
    _messaging.onTokenRefresh.listen(_upsertToken);

    // Foreground messages → afficher via local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Notification quotidienne a 18h
    await _scheduleDailyReminder();
  }

  /// Programme une notification locale tous les jours a 18h00.
  static const _dailyReminderId = 88000;

  static Future<void> _scheduleDailyReminder() async {
    try {
      tz.initializeTimeZones();
      final paris = tz.getLocation('Europe/Paris');

      // Annuler l'ancienne pour eviter les doublons
      await _localNotifications.cancel(_dailyReminderId);

      final now = tz.TZDateTime.now(paris);
      var scheduled = tz.TZDateTime(paris, now.year, now.month, now.day, 18, 0);
      // Si 18h est deja passe aujourd'hui, programmer pour demain
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        _dailyReminderId,
        'De nouveaux events t\'attendent !',
        'Decouvre les derniers evenements dans ta ville',
        scheduled,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[FCM] Notification quotidienne 18h programmee pour $scheduled');
    } catch (e) {
      debugPrint('[FCM] Erreur planification 18h: $e');
    }
  }

  /// Affiche la notification même quand l'app est au premier plan.
  static Future<void> _showForegroundNotification(
      RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('[FCM] foreground: ${notification.title}');

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
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
    );
  }

  static Future<void> _upsertToken(String token) async {
    try {
      final userId = await UserIdentityService.getUserId();
      final deviceId = await _getDeviceId();

      await _dio.post(
        'user_fcm_tokens',
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
      debugPrint('[FCM] token registered');
    } catch (e) {
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
