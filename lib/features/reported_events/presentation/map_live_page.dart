import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/branded/gradient_pill_button.dart';
import 'package:pulz_app/features/reported_events/presentation/snap_camera_screen.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_carousel.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_legend.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_map.dart';

/// Page dediee "Ça bouge près de toi" : map des signalements communautaires
/// (reported events) en pleine largeur, avec le bouton Live Notif pour en
/// publier un. Ouverte depuis un bouton "Map Live" sur le home.
class MapLivePage extends ConsumerWidget {
  const MapLivePage({super.key});

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
    final mapHeight = MediaQuery.of(context).size.height * 0.42;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MAP LIVE',
          style: GoogleFonts.geistMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.2,
            color: AppColors.textFaint,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : titre + pulse + Live Notif
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.line),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.flag, size: 12, color: AppColors.magenta),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ca bouge pres de toi',
                        style: GoogleFonts.geist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    GradientPillButton(
                      label: 'Live Notif',
                      onPressed: () => _openLiveReport(context),
                    ),
                  ],
                ),
              ),
              // Map grande
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ReportedEventsMap(height: mapHeight),
              ),
              const SizedBox(height: 10),
              // Legende
              const ReportedEventsLegend(),
              const SizedBox(height: 14),
              // Carousel bulles de signalements
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ReportedEventsCarousel(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
