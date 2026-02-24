import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pulz_app/core/theme/app_theme.dart';
import 'package:pulz_app/core/router/app_router.dart';

class PulzApp extends StatefulWidget {
  const PulzApp({super.key});

  @override
  State<PulzApp> createState() => _PulzAppState();
}

class _PulzAppState extends State<PulzApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Intercepte le bouton retour Android :
  /// - Sur un shell mode → retour a l'accueil
  /// - Sur l'accueil / splash → minimise l'app
  @override
  Future<bool> didPopRoute() async {
    final location =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location.startsWith('/mode/')) {
      appRouter.go('/home');
      return true;
    }
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaCity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
