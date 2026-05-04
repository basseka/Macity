import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/services/app_update_service.dart';

/// Ecran bloquant affiche au demarrage si la version locale est inferieure
/// au `min_version` defini dans `app_versions`. Pas de bouton "fermer" : le
/// user doit mettre a jour pour continuer.
class ForceUpdateScreen extends StatefulWidget {
  final AppUpdateStatus status;
  const ForceUpdateScreen({super.key, required this.status});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _busy = false;

  Future<void> _onUpdate() async {
    if (_busy) return;
    setState(() => _busy = true);

    final native = await AppUpdateService.instance.tryNativeFlow(immediate: true);
    if (native) {
      // Le flow Play Store IMMEDIATE prend le relai et redemarre l'app.
      return;
    }

    final url = widget.status.storeUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.status.latestVersion;
    final msg = widget.status.message ??
        'Une nouvelle version est requise pour continuer a utiliser l\'application.';
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1116),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.system_update, color: Colors.amber, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Mise a jour requise',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Derniere version : $latest',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _busy ? null : _onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          Platform.isAndroid ? 'Mettre a jour' : 'Ouvrir l\'App Store',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
