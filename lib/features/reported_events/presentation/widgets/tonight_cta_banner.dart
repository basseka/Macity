import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/tonight_events_sheet.dart';

/// Bandeau "Quoi faire ce soir" tout en haut du feed home, a cote de la
/// recherche : meme action que la bulle du meme nom plus bas dans
/// [PartnersOfDaySection] (ouvre [TonightEventsSheet]), juste rendue visible
/// sans avoir a scroller.
class TonightCtaBanner extends StatelessWidget {
  const TonightCtaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TonightEventsSheet.show(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.nightlife_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Quoi faire ce soir ?',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.geist(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
