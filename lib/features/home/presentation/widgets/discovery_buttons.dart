import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/home/presentation/sheets/right_now_sheet.dart';
import 'package:pulz_app/features/home/presentation/sheets/nearby_sheet.dart';
import 'package:pulz_app/features/home/presentation/sheets/top_picks_sheet.dart';
import 'package:pulz_app/features/home/presentation/sheets/weekend_picks_sheet.dart';

class DiscoveryButtons extends StatelessWidget {
  const DiscoveryButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _DiscoveryChip(
            emoji: '\uD83D\uDD25',
            label: 'Maintenant',
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E8C), Color(0xFFFF6B35)],
            ),
            onTap: () => RightNowSheet.show(context),
          ),
          const SizedBox(width: 8),
          _DiscoveryChip(
            emoji: '\uD83D\uDCCD',
            label: 'Proche',
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2D8E), Color(0xFF4A90D9)],
            ),
            onTap: () => NearbySheet.show(context),
          ),
          const SizedBox(width: 8),
          _DiscoveryChip(
            emoji: '\u2B50',
            label: 'Top',
            gradient: const LinearGradient(
              colors: [Color(0xFFE6A817), Color(0xFFE91E8C)],
            ),
            onTap: () => TopPicksSheet.show(context),
          ),
          const SizedBox(width: 8),
          _DiscoveryChip(
            emoji: '\uD83C\uDF89',
            label: 'Week-end',
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            onTap: () => WeekendPicksSheet.show(context),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _DiscoveryChip({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
