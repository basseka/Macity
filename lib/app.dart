import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/app_theme.dart';
import 'package:pulz_app/core/router/app_router.dart';

class PulzApp extends StatelessWidget {
  const PulzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaCity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
