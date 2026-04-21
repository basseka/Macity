import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/features/day/data/event_scan_service.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Compact launcher bottom sheet.
/// Shows a brief intro then navigates to the full-screen wizard.
/// Bonus : pour les pros approuves, un CTA "Scanner un flyer (IA)" lance
/// l'extraction auto via Claude Haiku 4.5 et pre-remplit le wizard.
class AddEventBottomSheet extends ConsumerWidget {
  final String? initialPhotoPath;

  const AddEventBottomSheet({super.key, this.initialPhotoPath});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro =
        ref.watch(proAuthProvider).status == ProAuthStatus.approved;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _primaryColor,
                    _primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: const Icon(Icons.event_available, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),

            const Text(
              'Creez votre evenement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Concert, atelier, sport, festival...\nPartagez votre evenement en quelques etapes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // CTA principal : flow manuel
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEventPage(
                        initialPhotoPath: initialPhotoPath,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Commencer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // CTA scan IA (pro uniquement)
            if (isPro) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onScanFlyer(context, ref),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text(
                    'Scanner un flyer (IA)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryDarkColor,
                    side: BorderSide(
                      color: _primaryColor.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Cancel
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onScanFlyer(BuildContext context, WidgetRef ref) async {
    await triggerScanFlow(
      context: context,
      ref: ref,
      closeParentSheet: true,
    );
  }

  /// Point d'entree reutilisable (nav bar + ce sheet) : choix camera/galerie,
  /// pick, loader IA, pre-remplissage du wizard, ouverture CreateEventPage.
  ///
  /// [closeParentSheet] : ferme un bottom sheet parent (true depuis
  /// AddEventBottomSheet lui-meme, false si appele depuis la nav bar ou un
  /// autre point d'entree).
  ///
  /// [alreadyOnWizard] : true si appele DEPUIS CreateEventPage (banner dans
  /// step_essentials). Dans ce cas on applique le prefill directement sur le
  /// provider deja subscribed et on ne push PAS de nouvelle page.
  /// Sinon (nav bar, menu compte) on passe les donnees par constructeur pour
  /// survivre a l'autoDispose du provider entre prefill et push.
  static Future<void> triggerScanFlow({
    required BuildContext context,
    required WidgetRef ref,
    bool closeParentSheet = false,
    bool alreadyOnWizard = false,
  }) async {
    // Capture le NavigatorState root une fois : meme si le BuildContext
    // d'origine devient invalide pendant l'attente (dispose du bottom sheet
    // parent, rebuild...), on peut toujours popper le dialog et pousser la
    // page via cette reference stable.
    final rootNav = Navigator.of(context, rootNavigator: true);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primaryColor),
              title: const Text('Prendre en photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primaryColor),
              title: const Text('Depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (xFile == null) return;

    final scanned = await _runScanWithLoader(rootNav, xFile.path);
    debugPrint('[ScanFlow] scan done, result=${scanned != null}');
    if (scanned == null) return;

    if (alreadyOnWizard) {
      // Provider est deja watched par le wizard en cours : prefill direct.
      ref.read(createEventProvider.notifier).prefillFromScan(
            data: scanned.data,
            photoUrl: scanned.photoUrl,
          );
      debugPrint('[ScanFlow] prefill applied on active wizard');
      return;
    }

    // Entree depuis l'exterieur (nav bar, menu compte) : on passe la prefill
    // via le constructeur pour eviter l'autoDispose entre prefill et build.
    debugPrint('[ScanFlow] pushing CreateEventPage with scan prefill');
    if (closeParentSheet) {
      try { rootNav.pop(); } catch (_) {}
    }
    await rootNav.push(
      MaterialPageRoute(
        builder: (_) => CreateEventPage(
          scanPrefillData: scanned.data,
          scanPrefillPhotoUrl: scanned.photoUrl,
        ),
      ),
    );
  }

  /// Overlay "IA en train d'analyser..." pendant l'upload + appel.
  /// Utilise le [NavigatorState] root capture en amont pour rester stable
  /// meme si le BuildContext initial a ete dispose.
  static Future<ScanEventResult?> _runScanWithLoader(
    NavigatorState rootNav,
    String localPath,
  ) async {
    ScanEventResult? result;
    String? errorMsg;

    // Push du dialog via le navigator root (pas de context requis).
    final dialogRoute = DialogRoute<void>(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (_) => const _ScanLoadingDialog(),
    );
    unawaited(rootNav.push(dialogRoute));

    try {
      result = await EventScanService().scanFlyer(localPath);
      debugPrint('[ScanFlow] service returned OK, photoUrl=${result.photoUrl}');
    } on ScanEventException catch (e) {
      debugPrint('[ScanFlow] service ScanEventException: ${e.message}');
      errorMsg = e.message;
    } catch (e, st) {
      debugPrint('[ScanFlow] service unexpected error: $e\n$st');
      errorMsg = 'Erreur inattendue : $e';
    }

    // Ferme le dialog via la route capturee (evite les mismatches de navigator).
    if (dialogRoute.isActive) {
      rootNav.removeRoute(dialogRoute);
    }

    if (errorMsg != null) {
      final ctx = rootNav.context;
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return result;
  }
}

class _ScanLoadingDialog extends StatelessWidget {
  const _ScanLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF7B2D8E),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Analyse du flyer...',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Quelques secondes',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

