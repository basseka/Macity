import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/trip_planner/presentation/trip_planner_sheet.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Bouton « Organiser mon trip » : questionnaire puis feuille de route.
/// Affiché sur l'accueil, sous la rangée « Quoi faire ce soir ».
class TripPlannerButton extends ConsumerWidget {
  const TripPlannerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => TripPlannerSheet.show(
          context,
          ville: ref.read(selectedCityProvider),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          // Couleurs de l'app (degrade magenta -> violet), pas celles de Food.
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.neon(AppColors.magenta, blur: 16, y: 6),
          ),
          child: Row(
            children: [
              const Text('🧭', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.tripPlanTitle,
                        style: FoodTokens.bannerTitle()
                            .copyWith(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(context.l10n.tripPlanSubtitle,
                        style: FoodTokens.meta(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
