import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

class CityListTile extends StatelessWidget {
  final VilleModel ville;
  final VoidCallback? onTap;

  const CityListTile({
    super.key,
    required this.ville,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.location_city,
          color: AppColors.textDim,
          size: 18,
        ),
      ),
      title: Text(
        ville.nom,
        style: GoogleFonts.geist(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        [
          if (ville.codePostal.isNotEmpty) ville.codePostal,
          if (ville.departement.isNotEmpty) ville.departement,
        ].join(' - '),
        style: GoogleFonts.geist(
          color: AppColors.textFaint,
          fontSize: 12,
        ),
      ),
      trailing: ville.population > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceHi,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                ville.populationFormatted,
                style: GoogleFonts.geistMono(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
  }
}
