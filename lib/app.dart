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
  /// 1. Bottom sheet / dialog ouverte → la ferme
  /// 2. Sur /home → minimise l'app
  /// 3. Ailleurs → retour a /home
  @override
  Future<bool> didPopRoute() async {
    // 1. Fermer les modales (bottom sheets, dialogs) sur le root navigator
    final rootNav = appRouter.routerDelegate.navigatorKey.currentState;
    if (rootNav != null && rootNav.canPop()) {
      rootNav.pop();
      return true;
    }

    // 2. Sur l'accueil → minimise l'app
    final location =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location == '/home' || location == '/') {
      await SystemNavigator.pop();
      return true;
    }

    // 3. Sur tout autre ecran → retour a l'accueil
    appRouter.go('/home');
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
