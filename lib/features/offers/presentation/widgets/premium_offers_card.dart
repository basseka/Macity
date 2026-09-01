import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/features/offers/presentation/teaser_video_screen.dart';

/// Carte « Offres premium » (abonnement BeThere), sous le header ville.
///
/// Couleurs EN DUR (handoff design "Offres — refonte", fev. 2026) : cette
/// carte reste sombre quel que soit `AppColors.isLightTheme`, meme raison que
/// les autres blocs d'Explorer (cf. commentaire dans `explorer_screen.dart`).
///
/// Volontairement generique sur le contenu des categories : pas de nom de
/// commercant ni de compte d'offres chiffre tant que l'inventaire premium
/// n'existe pas reellement (`subscription_screen.dart` est encore un
/// placeholder sans IAP branche).
const _categories = <({String label, List<Color> degrade})>[
  (label: 'Restos', degrade: [Color(0xFF7A3410), Color(0xFF4A1E08)]),
  (label: 'Bars', degrade: [Color(0xFF6B21C8), Color(0xFF3B1173)]),
  (label: 'Bien-être', degrade: [Color(0xFF0F7F72), Color(0xFF07423C)]),
];

/// URL de la video de teasing, pilotee par la base (`app_config`).
final premiumTeaserVideoProvider = FutureProvider<String>((ref) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
      ..interceptors.add(SupabaseInterceptor());
    final res = await dio.get(
      'app_config',
      queryParameters: {
        'select': 'value',
        'key': 'eq.teaser_video_url',
      },
    );
    final rows = res.data as List;
    return rows.isEmpty ? '' : (rows.first['value'] as String? ?? '');
  } catch (_) {
    // Reseau indisponible : la carte reste utilisable, elle mene juste
    // directement a l'abonnement plutot qu'a la video de teasing.
    return '';
  }
});

class PremiumOffersCard extends ConsumerWidget {
  const PremiumOffersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUrl = ref.watch(premiumTeaserVideoProvider).valueOrNull ?? '';
    void openTeaser() => TeaserVideoScreen.ouvrir(context, videoUrl: videoUrl);

    return Padding(
      // Aligne avec le titre/filtres/grille en dessous, qui utilisent tous
      // EditorialSpacing.screen (le handoff design indique 22px partout,
      // mais le reste de cet ecran est deja cale sur 20).
      padding: const EdgeInsets.symmetric(horizontal: EditorialSpacing.screen),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF17102B),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17102B).withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '✦',
                  style: TextStyle(color: Color(0xFFF5197F), fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Offres premium',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Boite claire derriere le logo : le logo BeThere reel est
                // noir + or sur fond transparent, illisible directement sur
                // cette carte sombre.
                Container(
                  width: 78,
                  height: 34,
                  // Pas de padding : le logo est deja loin des bords une fois
                  // contraint par la hauteur (image large 1.5:1 dans une
                  // bulle plus large que haute), du padding en plus ne
                  // faisait que le rapetisser sans raison.
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF6EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFC9962B).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/bethere-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '3 offres exclusives de plus chaque mois, dans tes catégories '
              'préférées.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0x9EFBF5EA),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < _categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _ChipVerrouille(
                      categorie: _categories[i],
                      onTap: openTeaser,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: openTeaser,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5197F),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5197F).withValues(alpha: 0.7),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                // Prix reel de l'abonnement BeThere, cf. subscription_screen.
                child: const Text(
                  'Débloquer · 5,90 €/mois',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipVerrouille extends StatelessWidget {
  final ({String label, List<Color> degrade}) categorie;
  final VoidCallback onTap;

  const _ChipVerrouille({required this.categorie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: categorie.degrade,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 11,
              color: Color(0xFFE8B54B),
            ),
            const SizedBox(height: 4),
            Text(
              categorie.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
