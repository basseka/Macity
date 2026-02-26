import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulz_app/app.dart';
import 'package:pulz_app/core/services/fcm_service.dart';
import 'package:pulz_app/firebase_options.dart';

/// Handler pour les messages recus quand l'app est en background/killed.
/// Doit etre une top-level function (pas une methode de classe).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // Catch Flutter framework errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Lancer l'UI immediatement (affiche le splash MaCity tout de suite).
  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: PulzApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Unhandled error: $error');
      debugPrint('$stackTrace');
    },
  );

  // Initialiser Firebase en arriere-plan pendant que le splash est visible.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FcmService.init();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
}
