import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/services/app_update_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Ecran bloquant affiche au demarrage si la version locale est inferieure
/// au `min_version` defini dans `app_versions`. Pas de bouton "fermer" : le
/// user doit mettre a jour pour continuer.
///
/// Design aligne sur la palette MaCity : fond noir profond, glow neon
/// magenta + gold, typo Geist/Instrument Serif, bouton gradient editorial.
class ForceUpdateScreen extends StatefulWidget {
  final AppUpdateStatus status;
  const ForceUpdateScreen({super.key, required this.status});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUpdate() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Le flux natif IMMEDIATE mene normalement a un redemarrage de l'app.
    // Mais si l'user ANNULE l'overlay Play (le plugin resout alors `true`
    // sans relancer l'app), on ne doit PAS rester bloque sur le spinner :
    // on retombe sur le store seulement si le natif n'a pas pris le relai,
    // et on remet TOUJOURS _busy a false pour debloquer le bouton.
    final native = await AppUpdateService.instance.tryNativeFlow(immediate: true);
    if (!native) {
      final url = widget.status.effectiveStoreUrl;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icone gradient editorial avec halo pulsant
                Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo radial qui pulse
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.magenta.withValues(
                                      alpha: 0.18 + 0.22 * _pulse.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Disque central
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.primary,
                              boxShadow: AppShadows.neon(
                                AppColors.magenta,
                                blur: 28,
                                y: 0,
                              ),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Titre : "Mise à" en geist + "jour" en italic gradient
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Mise à ',
                      style: GoogleFonts.geist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      'jour',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                        foreground: Paint()
                          ..shader = AppGradients.editorial.createShader(
                            const Rect.fromLTWH(0, 0, 120, 40),
                          ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.geist(
                    color: AppColors.textDim,
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: -0.1,
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      'v$latest disponible',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.geistMono(
                        color: AppColors.textFaint,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                // Bouton gradient primary avec glow neon
                GestureDetector(
                  onTap: _busy ? null : _onUpdate,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.neon(
                        AppColors.magenta,
                        blur: 20,
                        y: 6,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            Platform.isAndroid
                                ? 'Mettre à jour'
                                : 'Ouvrir l\'App Store',
                            style: GoogleFonts.geist(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pour profiter des dernières fonctionnalités',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.geist(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
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
