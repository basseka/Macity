import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/account_menu.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

/// Brand row partagee entre Home et Explorer — clone exact de la row utilisee
/// dans `feed_screen.dart::_buildBrandRow` (logo + TA VILLE + ville + prenom +
/// avatar). Maintenue identique pixel a pixel entre les deux ecrans.
class EditorialCityHeader extends ConsumerWidget {
  const EditorialCityHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prenom = ref.watch(userPrenomProvider).valueOrNull ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.brand),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CityPickerBottomSheet(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TA VILLE',
                    style: GoogleFonts.geistMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                      color: AppColors.textFaint,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ref.watch(selectedCityProvider),
                        style: GoogleFonts.geist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.textDim,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (prenom.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                prenom,
                style: GoogleFonts.geist(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AccountMenu.show(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AccountMenu.buildButton(ref: ref),
            ),
          ),
        ],
      ),
    );
  }
}
