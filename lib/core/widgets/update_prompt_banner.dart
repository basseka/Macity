import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/services/app_update_service.dart';

/// Banniere fine au-dessus du contenu, affichee quand une nouvelle version
/// est dispo mais pas encore obligatoire (status = updateAvailable).
/// Dismissible — l'utilisateur peut la cacher pour la session courante.
class UpdatePromptBanner extends StatefulWidget {
  final AppUpdateStatus status;
  final VoidCallback onDismissed;
  const UpdatePromptBanner({
    super.key,
    required this.status,
    required this.onDismissed,
  });

  @override
  State<UpdatePromptBanner> createState() => _UpdatePromptBannerState();
}

class _UpdatePromptBannerState extends State<UpdatePromptBanner> {
  bool _busy = false;

  Future<void> _onUpdate() async {
    if (_busy) return;
    setState(() => _busy = true);

    final native = await AppUpdateService.instance.tryNativeFlow(immediate: false);
    if (native) {
      if (mounted) widget.onDismissed();
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
    if (!widget.status.isUpdateAvailable) return const SizedBox.shrink();
    final latest = widget.status.latestVersion;
    final msg = widget.status.message;

    return Material(
      color: Colors.amber.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg ?? 'Nouvelle version disponible${latest != null ? " ($latest)" : ""}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _onUpdate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(Platform.isAndroid ? 'Mettre a jour' : 'App Store'),
              ),
              IconButton(
                onPressed: widget.onDismissed,
                icon: const Icon(Icons.close, color: Colors.black, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Plus tard',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
