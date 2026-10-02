import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/branded/gradient_pill_button.dart';
import 'package:pulz_app/features/reported_events/presentation/snap_camera_screen.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_carousel.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_legend.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_map.dart';

/// Page dediee "Ça bouge près de toi", facon Snap Map : la carte des
/// signalements communautaires occupe tout l'ecran, et tout le reste flotte
/// par-dessus (retour, titre, Live Notif et legende en haut ; bulles des
/// stories en bas). Ouverte depuis un bouton "Map Live" sur le home.
class MapLivePage extends ConsumerWidget {
  const MapLivePage({super.key});

  /// Hauteur de la bande des stories posee sur le bas de la carte.
  static const _storiesBand = 84.0;

  void _openLiveReport(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SnapCameraScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = MediaQuery.of(context).padding;
    final storiesBottom = pad.bottom + 12;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Carte claire sous la barre d'etat : icones sombres.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1EEE9),
        body: Stack(
          children: [
            // ── Carte bord a bord ──
            Positioned.fill(
              child: ReportedEventsMap(
                height: double.infinity,
                fullscreen: true,
                locateBottom: storiesBottom + _storiesBand + 12,
              ),
            ),

            // ── Haut : degrade discret pour lire les boutons ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: pad.top + 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x55000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _GlassChip(
                            child: Text(
                              'Ça bouge près de toi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.geist(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GradientPillButton(
                        label: 'Live Notif',
                        onPressed: () => _openLiveReport(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _GlassChip(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(width: 300, child: ReportedEventsLegend()),
                  ),
                ],
              ),
            ),

            // ── Bas : stories posees sur la carte ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: storiesBottom + _storiesBand + 30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 0,
              bottom: storiesBottom,
              child: const ReportedEventsCarousel(onMap: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton rond sombre translucide (retour), comme les commandes Snap Map.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC1C1C22),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Pastille sombre translucide posee sur la carte.
class _GlassChip extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassChip({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xCC1C1C22),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
