import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Bouton « Voir l'album » bien visible sur les cartes d'event (Mes events
/// prives, Mes invitations) : pastille appareil photo, nombre de photos,
/// chevron.
class AlbumButton extends StatelessWidget {
  final int photoCount;
  final VoidCallback onTap;
  const AlbumButton({super.key, required this.photoCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final empty = photoCount == 0;
    return Material(
      color: AppColors.magenta.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.magenta.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                ),
                child: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empty ? 'Album photo' : 'Voir l\'album',
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.magenta,
                      ),
                    ),
                    Text(
                      empty
                          ? 'Ajoute les premières photos de la soirée'
                          : '$photoCount photo${photoCount > 1 ? 's' : ''} · diaporama',
                      style: GoogleFonts.geist(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.magenta),
            ],
          ),
        ),
      ),
    );
  }
}
