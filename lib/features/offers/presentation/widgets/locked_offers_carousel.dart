import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/offers/presentation/teaser_video_screen.dart';

/// Carrousel « Offres réservées aux abonnés », sous la grille des offres.
///
/// ⚠️ Les cartes sont VOLONTAIREMENT GÉNÉRIQUES : aucun nom de commerçant,
/// aucune remise chiffrée. Afficher « −50 % chez X » alors que X n'a rien signé
/// ferait payer l'abonnement pour une promesse invérifiable — remboursements et
/// signalement sur les stores à la clé. Ici on ne montre qu'une catégorie et un
/// visuel flouté : la curiosité joue, sans rien affirmer de faux.
///
/// Au tap : une vidéo de présentation (URL dans `app_config.teaser_video_url`),
/// puis la proposition d'abonnement. Si l'URL est vide, on va droit à
/// l'abonnement — la fonctionnalité reste utilisable avant que la vidéo existe.

/// Catégories affichées. Ce sont des familles d'offres, pas des établissements.
const _categories = <({String label, IconData icone, List<Color> degrade})>[
  (label: 'Restaurants',  icone: Icons.restaurant_rounded,   degrade: [Color(0xFF7A3B22), Color(0xFFC2410C)]),
  (label: 'Bars & clubs', icone: Icons.local_bar_rounded,    degrade: [Color(0xFF4C1D95), Color(0xFF9333EA)]),
  (label: 'Bien-être',    icone: Icons.spa_rounded,          degrade: [Color(0xFF134E4A), Color(0xFF14B8A6)]),
  (label: 'Sorties',      icone: Icons.local_activity_rounded, degrade: [Color(0xFF831843), Color(0xFFE11D48)]),
  (label: 'Culture',      icone: Icons.theater_comedy_rounded, degrade: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
  (label: 'En famille',   icone: Icons.family_restroom_rounded, degrade: [Color(0xFF713F12), Color(0xFFEAB308)]),
];

/// Réglages pilotés par la base : nombre de cartes et URL de la vidéo.
final lockedOffersConfigProvider =
    FutureProvider<({int nombre, String videoUrl})>((ref) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
      ..interceptors.add(SupabaseInterceptor());
    final res = await dio.get('app_config', queryParameters: {
      'select': 'key,value',
      'key': 'in.(teaser_video_url,locked_offers_count)',
    });
    final map = <String, String>{};
    for (final r in (res.data as List)) {
      map[r['key'] as String] = (r['value'] as String?) ?? '';
    }
    return (
      nombre: int.tryParse(map['locked_offers_count'] ?? '') ?? 6,
      videoUrl: map['teaser_video_url'] ?? '',
    );
  } catch (_) {
    // Réseau indisponible : on garde le carrousel avec ses valeurs par défaut
    // plutôt que de faire disparaître la section.
    return (nombre: 6, videoUrl: '');
  }
});

class LockedOffersCarousel extends ConsumerWidget {
  const LockedOffersCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(lockedOffersConfigProvider).valueOrNull;
    final n = (cfg?.nombre ?? 6).clamp(1, _categories.length);
    final videoUrl = cfg?.videoUrl ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFC79A3E)),
              const SizedBox(width: 7),
              Text(
                'Réservé aux abonnés',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Text(
            'Des offres supplémentaires chaque mois, à débloquer avec l\'abonnement.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            itemCount: n,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _CarteVerrouillee(
              categorie: _categories[i % _categories.length],
              onTap: () => TeaserVideoScreen.ouvrir(context, videoUrl: videoUrl),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarteVerrouillee extends StatelessWidget {
  final ({String label, IconData icone, List<Color> degrade}) categorie;
  final VoidCallback onTap;
  const _CarteVerrouillee({required this.categorie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: categorie.degrade,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Le flou porte sur un fond abstrait, pas sur un contenu masqué :
            // il n'y a rien derrière, et c'est assumé.
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const ColoredBox(color: Color(0x33000000)),
            ),
            Center(
              child: Icon(categorie.icone,
                  size: 44, color: Colors.white.withValues(alpha: 0.30)),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFC79A3E).withValues(alpha: 0.75),
                      width: 1),
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 13, color: Color(0xFFC79A3E)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categorie.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Offre réservée',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
