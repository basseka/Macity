import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulz_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // Catch Flutter framework errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Catch async errors that escape the Flutter framework.
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
}
