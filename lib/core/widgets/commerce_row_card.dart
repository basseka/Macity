import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_pager_view.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';
import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/pro_auth/data/pro_venue_service.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/reviews/domain/models/commerce_review.dart';
import 'package:pulz_app/features/reviews/presentation/reviews_section.dart';
import 'package:pulz_app/features/reviews/state/commerce_summaries_provider.dart';

/// Carte commerce en ligne : image a gauche, infos a droite.
class CommerceRowCard extends ConsumerWidget {
  final CommerceModel commerce;
  final String? imageAsset;
  /// Si fourni, override le handler de tap par defaut (qui ouvre le sheet
  /// generique ItemDetailSheet). Utilise par la rubrique Food pour router
  /// vers RestaurantDetailSheet (avec CTA Reserver + badges).
  final VoidCallback? onTap;

  /// Liste complete dans laquelle l'utilisateur navigue. Si fournie (avec
  /// [pagerIndex]), le tap ouvre un pager swipable au lieu d'une fiche isolee.
  final List<CommerceModel>? pagerSiblings;

  /// Position de [commerce] dans [pagerSiblings].
  final int? pagerIndex;

  const CommerceRowCard({
    super.key,
    required this.commerce,
    this.imageAsset,
    this.onTap,
    this.pagerSiblings,
    this.pagerIndex,
  });

  /// Retourne la photo DB, l'asset explicite, ou la pochette par defaut.
  String? _resolveImage() => _resolveImageFor(commerce, imageAsset);

  static String? _resolveImageFor(CommerceModel commerce, String? imageAsset) {
    if (imageAsset != null) return imageAsset;
    if (commerce.photo.isNotEmpty && commerce.photo.startsWith('http')) {
      return commerce.photo;
    }
    return _categoryFallbackAsset(commerce.categorie);
  }

  /// Normalise une chaine : lowercase + retire les accents. Indispensable
  /// pour matcher "médiathèque" (DB) avec "mediatheque" (constante code).
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c');
  }

  static String? _categoryFallbackAsset(String category) {
    final cat = _normalize(category);
    if (cat.contains('coquin')) return 'assets/images/pochette_coquin.webp';
    if (cat.contains('strip')) return 'assets/images/pochette_strip.webp';
    if (cat.contains('spicy')) return 'assets/images/pochette_spicy.webp';
    if (cat.contains('club') || cat.contains('discotheque')) return 'assets/images/pochette_discotheque.webp';
    if (cat.contains('bar') && cat.contains('cocktail')) return 'assets/images/pochette_barcocktail.webp';
    if (cat.contains('pub')) return 'assets/images/sc_pub.jpg';
    if (cat.contains('bar') && cat.contains('nuit')) return 'assets/images/pochette_default.jpg';
    if (cat.contains('chicha')) return 'assets/images/pochette_chicha.webp';
    if (cat.contains('hotel')) return 'assets/images/sc_hotel.jpg';
    if (cat.contains('epicerie')) return 'assets/images/pochette_epicerie.jpg';
    if (cat.contains('restaurant')) return 'assets/images/pochette_restaurant.jpg';
    if (cat.contains('cinema')) return 'assets/images/pochette_cinema.webp';
    if (cat.contains('musee')) return 'assets/images/pochette_musee.webp';
    if (cat.contains('theatre')) return 'assets/images/pochette_theatre.webp';
    if (cat.contains('fitness') || cat.contains('sport')) return 'assets/images/pochette_fitnesspark.webp';
    if (cat.contains('natation') || cat.contains('piscine')) return 'assets/images/pochette_natation.jpg';
    if (cat.contains('gaming') || cat.contains('arcade')) return 'assets/images/pochette_gaming.jpg';
    if (cat.contains('yoga')) return 'assets/images/pochette_yoga.jpg';
    if (cat.contains('bowling')) return 'assets/images/pochette_bowling.webp';
    if (cat.contains('bibliotheque') || cat.contains('mediatheque')) return 'assets/images/pochette_bibliotheque.jpg';
    if (cat.contains('monument')) return 'assets/images/pochette_monument.jpg';
    if (cat.contains('opera')) return 'assets/images/pochette_opera.jpg';
    return null;
  }

  /// Placeholder final : asset catégorie si dispo, sinon icône sur fond teint.
  Widget _fallbackPlaceholder(ModeTheme modeTheme) {
    final assetFallback = _categoryFallbackAsset(commerce.categorie);
    if (assetFallback != null) {
      return Image.asset(
        assetFallback,
        fit: BoxFit.cover,
        cacheWidth: 300,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Container(
          color: modeTheme.chipBgColor,
          child: Center(
            child: Icon(
              _categoryIcon(commerce.categorie),
              size: 28,
              color: modeTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return Container(
      color: modeTheme.chipBgColor,
      child: Center(
        child: Icon(
          _categoryIcon(commerce.categorie),
          size: 28,
          color: modeTheme.primaryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildImage(String? image, ModeTheme modeTheme) {
    // Pas de photo DB → placeholder catégorie ou icône
    if (image == null) {
      return _fallbackPlaceholder(modeTheme);
    }

    final src = image;
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: src,
        memCacheWidth: 400,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        placeholder: (_, __) => Container(color: modeTheme.chipBgColor),
        // Fallback : si l'URL http est cassée, on affiche l'asset catégorie
        // au lieu d'un carré vide.
        errorWidget: (_, __, ___) => _fallbackPlaceholder(modeTheme),
      );
    }

    return Image.asset(
      src,
      fit: BoxFit.cover,
      cacheWidth: 300,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _fallbackPlaceholder(modeTheme),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final image = _resolveImage();

    // Pastille notes : prefetch en batch (debounce 50ms cote notifier).
    final hasReviewTarget =
        commerce.sourceId != null && commerce.sourceTable != null;
    if (hasReviewTarget) {
      ref.read(commerceSummariesProvider.notifier).request(
            commerce.sourceTable!,
            commerce.sourceId!,
          );
    }
    final summaryKey = hasReviewTarget
        ? '${commerce.sourceTable}:${commerce.sourceId}'
        : '';
    final summary = hasReviewTarget
        ? ref.watch(
            commerceSummariesProvider.select((m) => m[summaryKey]),
          )
        : null;

    return GestureDetector(
      onTap: onTap ?? () => _openDetail(context),
      child: Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Pochette image + note dessous a gauche ──
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: modeTheme.primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: _buildImage(image, modeTheme),
                        ),
                      ),
                      if (commerce.isVerified)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium, size: 14, color: Color(0xFFFFD700)),
                          ),
                        ),
                    ],
                  ),
                  if (summary != null && summary.reviewCount > 0) ...[
                    const SizedBox(height: 4),
                    _RatingPill(summary: summary),
                  ],
                ],
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            commerce.nom,
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.15,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (commerce.isVerified)
                          const VerifiedBadge.small()
                        else
                          _ClaimButton.small(
                            commerceName: commerce.nom,
                            sourceTable: _claimSourceTableFromSingular(commerce.sourceTable),
                            sourceId: commerce.sourceId,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (commerce.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        commerce.horaires,
                        modeTheme.primaryColor,
                      ),
                    if (commerce.displayCount > 0)
                      _buildInfoRow(
                        Icons.people_outline,
                        '${commerce.displayCount} personnes',
                        modeTheme.primaryColor.withValues(alpha: 0.7),
                      ),

                    const SizedBox(height: 4),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildLikeIcon(ref),
                        const SizedBox(width: 8),
                        _buildActionIcon(
                          Icons.share_outlined,
                          AppColors.textFaint,
                          () {
                            final buffer = StringBuffer();
                            buffer.writeln(commerce.nom);
                            if (commerce.adresse.isNotEmpty) {
                              buffer.writeln(commerce.adresse);
                            }
                            buffer.writeln('\nDecouvre sur MaCity');
                            Share.share(buffer.toString());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _openDetail(BuildContext context) => openDetail(
        context,
        commerce,
        imageAsset: imageAsset,
        siblings: pagerSiblings,
        index: pagerIndex,
      );

  /// Convertit le `sourceTable` singulier (convention reviews :
  /// 'venue', 'etablissement') vers le pluriel attendu par les RPC
  /// pro (`claim_with_macity_code`, `is_pro_owner_of_*`, etc.).
  static String? _claimSourceTableFromSingular(String? singular) {
    if (singular == null) return null;
    switch (singular) {
      case 'venue':
        return 'venues';
      case 'etablissement':
        return 'etablissements';
      default:
        return singular;
    }
  }

  /// Construit le widget ItemDetailSheet pour ce commerce. Reutilise par
  /// showDetailSheet (popup classique) et par les pagers swipables qui
  /// rendent plusieurs commerces a la suite (ex: CommercePagerView).
  static ItemDetailSheet buildDetailSheet(
    CommerceModel commerce, {
    String? imageAsset,
  }) {
    final image = _resolveImageFor(commerce, imageAsset);
    final isNetwork = image != null && image.startsWith('http');
    return ItemDetailSheet(
        title: commerce.nom,
        emoji: '',
        imageAsset: isNetwork ? null : image,
        imageUrl: isNetwork ? image : null,
        videoUrl: commerce.videoUrl.isNotEmpty
            ? commerce.videoUrl
            : _defaultVideoUrlFor(commerce),
        likeId: 'night_${commerce.nom}',
        isVerified: commerce.isVerified,
        claimSourceTable: _claimSourceTableFromSingular(commerce.sourceTable),
        claimSourceId: commerce.sourceId,
        photoGallery: _buildPhotoGalleryFor(commerce),
        description: commerce.description,
        infos: [
          if (commerce.categorie.isNotEmpty)
            DetailInfoItem(Icons.category_outlined, commerce.categorie),
          if (commerce.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, commerce.horaires),
          if (commerce.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, commerce.adresse),
          if (commerce.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, commerce.telephone),
        ],
        primaryAction: commerce.siteWeb.isNotEmpty
            ? DetailAction(
                icon: commerce.siteWeb.contains('instagram') ? Icons.camera_alt : Icons.language,
                label: commerce.siteWeb.contains('instagram') ? 'Instagram' : 'Site web',
                url: commerce.siteWeb,
              )
            : null,
        secondaryActions: [
          if (commerce.lienMaps.isNotEmpty)
            DetailAction(
              icon: Icons.map_outlined,
              label: 'Maps',
              url: commerce.lienMaps,
            ),
          if (commerce.telephone.isNotEmpty)
            DetailAction(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              url: 'tel:${commerce.telephone.replaceAll(' ', '')}',
            ),
        ],
        shareText: _buildShareTextFor(commerce),
        reviewsTarget: (commerce.sourceId != null && commerce.sourceTable != null)
            ? ReviewsTarget(
                kind: commerce.sourceTable!,
                id: commerce.sourceId!,
                name: commerce.nom,
              )
            : null,
      );
  }

  /// Ouvre le sheet detail pour un commerce isole. Pour swiper entre
  /// plusieurs commerces, utiliser un pager (ex: CommercePagerView).
  static void showDetailSheet(
    BuildContext context,
    CommerceModel commerce, {
    String? imageAsset,
  }) {
    ItemDetailSheet.show(
      context,
      buildDetailSheet(commerce, imageAsset: imageAsset),
    );
  }

  /// Ouvre un pager swipable plein ecran sur [commerces], positionne a [index].
  static Future<void> openPager(
    BuildContext context,
    List<CommerceModel> commerces,
    int index,
  ) {
    return CommercePagerView.open(
      context,
      commerces: commerces,
      initialIndex: index,
    );
  }

  /// Ouvre le detail d'un commerce. Si [siblings] (la liste dans laquelle
  /// navigue l'utilisateur) est fournie avec [index], ouvre un pager swipable
  /// positionne sur cet item ; sinon, ouvre la fiche isolee.
  static void openDetail(
    BuildContext context,
    CommerceModel commerce, {
    String? imageAsset,
    List<CommerceModel>? siblings,
    int? index,
  }) {
    if (siblings != null && siblings.length > 1 && index != null) {
      openPager(context, siblings, index);
    } else {
      showDetailSheet(context, commerce, imageAsset: imageAsset);
    }
  }

  /// Photos generiques pour les clubs/discotheques non revendiques.
  static const _defaultClubPhotos = [
    'assets/images/club-pic-default-01.png',
    'assets/images/club-pic-default-02.png',
    'assets/images/club-pic-default-03.png',
    'assets/images/club-pic-default-04.png',
    'assets/images/club-pic-default-05.png',
    'assets/images/club-pic-default-06.png',
  ];

  static const _defaultRestaurantPhotos = [
    'assets/images/plat-01.png',
    'assets/images/plat-02.png',
    'assets/images/plat-03.png',
    'assets/images/plat-04.png',
    'assets/images/plat-05.png',
    'assets/images/plat-06.png',
  ];

  /// Photos generiques pour les salles de sport non revendiquees.
  /// 6 images a uploader dans le bucket public `photos`, dossier
  /// `sport_venues/`, nommees default_1.jpg ... default_6.jpg.
  static const _sportPhotosBase =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/photos/sport_venues';
  static const _defaultSportPhotos = [
    '$_sportPhotosBase/default_1.jpg',
    '$_sportPhotosBase/default_2.jpg',
    '$_sportPhotosBase/default_3.jpg',
    '$_sportPhotosBase/default_4.jpg',
    '$_sportPhotosBase/default_5.jpg',
    '$_sportPhotosBase/default_6.jpg',
  ];

  /// Photos generiques — repli universel pour toute fiche sans media
  /// (Culture, Famille, etc.). 6 images a uploader dans le bucket public
  /// `photos`, dossier `defaults/`, nommees default_1.jpg ... default_6.jpg.
  static const _genericPhotosBase =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/photos/defaults';
  static const _defaultGenericPhotos = [
    '$_genericPhotosBase/default_1.jpg',
    '$_genericPhotosBase/default_2.jpg',
    '$_genericPhotosBase/default_3.jpg',
    '$_genericPhotosBase/default_4.jpg',
    '$_genericPhotosBase/default_5.jpg',
    '$_genericPhotosBase/default_6.jpg',
  ];

  /// Construit la galerie photo pour le detail.
  /// Priorite : photos[] uploadees par le pro > photo principale > defaults
  /// generiques (uniquement si la fiche n'a pas ete revendiquee).
  static List<String> _buildPhotoGalleryFor(CommerceModel commerce) {
    // 1. Si le pro a uploade des photos, on utilise CELLES-LA en priorite.
    if (commerce.photos.isNotEmpty) {
      return commerce.photos.take(6).toList();
    }

    // 2. Sinon photo principale + fallback defaults pour les fiches non
    //    revendiquees (donne du visuel meme quand le pro n'a rien charge).
    final photos = <String>[];
    if (commerce.photo.isNotEmpty && commerce.photo.startsWith('http')) {
      photos.add(commerce.photo);
    }

    if (!commerce.isVerified && photos.length < 6) {
      final cat = commerce.categorie.toLowerCase();
      final List<String> defaults;
      if (cat.contains('club') || cat.contains('discotheque')) {
        defaults = _defaultClubPhotos;
      } else if (cat.contains('restaurant') || cat.contains('food') || cat.contains('brunch') || cat.contains('salon de the') || cat.contains('buffet') || cat.contains('guinguette')) {
        defaults = _defaultRestaurantPhotos;
      } else if (commerce.sourceTable == 'sport_venues') {
        defaults = _defaultSportPhotos;
      } else {
        // Repli universel (Culture, Famille, fiches sans categorie connue).
        defaults = _defaultGenericPhotos;
      }
      for (final p in defaults) {
        if (photos.length >= 6) break;
        if (!photos.contains(p)) photos.add(p);
      }
    }

    return photos;
  }

  /// Video par defaut pour les clubs/discotheques non revendiques.
  static const _defaultClubVideo =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/user-events/teaser_disco_1.mp4';

  static const _bannersBase =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/videos/banners';

  /// Video par defaut pour les salles de sport non revendiquees.
  static const _defaultSportVideo = '$_bannersBase/sport.mp4';
  static const _defaultCultureVideo = '$_bannersBase/culture.mp4';
  static const _defaultFamilyVideo = '$_bannersBase/family.mp4';
  /// Public : reutilise par les mappers RestaurantVenue -> CommerceModel
  /// (les categories food sont trop variees pour matcher par mots-cles fiables).
  static const defaultFoodVideo = '$_bannersBase/food.mp4';
  static const _defaultGamingVideo = '$_bannersBase/gaming.mp4';

  /// Video par defaut — repli universel (mode Day, etc.).
  static const _defaultGenericVideo = '$_bannersBase/day.mp4';

  /// Normalise une chaine pour matching : minuscules + accents francais
  /// retires. Sans ca, `'cinéma'.contains('cinema')` retourne false a cause
  /// du é, et toutes les fiches Culture ('cinéma', 'théâtre', 'musée',
  /// 'bibliothèque', 'médiathèque', 'opéra') tombent sur day.mp4.
  static String _normalizeForMatch(String s) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'û': 'u', 'ù': 'u', 'ü': 'u',
      'ç': 'c',
    };
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(accents[ch] ?? ch);
    }
    return buf.toString();
  }

  static String? _defaultVideoUrlFor(CommerceModel commerce) {
    if (commerce.isVerified) return null;

    // Sport : table dediee, prioritaire sur le matching par categorie.
    if (commerce.sourceTable == 'sport_venues') {
      return _defaultSportVideo;
    }

    final cat = _normalizeForMatch(commerce.categorie);

    // Night : clubs / discotheques (les autres categories "de nuit"
    // — bar, pub, tabac, epicerie — retombent sur le fallback day.mp4).
    if (cat.contains('club') || cat.contains('discotheque')) {
      return _defaultClubVideo;
    }

    // Famille : verifie AVANT food pour que "Restaurant familial" matche ici.
    if (cat.contains('familial') ||
        cat.contains('aire de jeux') ||
        cat.contains('parc') ||
        cat.contains('attraction') ||
        cat.contains('ferme') ||
        cat.contains('accrobranche') ||
        cat.contains('mini golf') ||
        cat.contains('mini-golf') ||
        cat.contains('trampoline') ||
        cat.contains('aquarium') ||
        cat.contains('zoo') ||
        cat.contains('bowling') ||
        cat.contains('patinoire') ||
        cat.contains('kart')) {
      return _defaultFamilyVideo;
    }

    // Gaming
    if (cat.contains('escape') ||
        cat.contains('laser') ||
        cat.contains('gaming') ||
        cat.contains('arcade') ||
        cat.contains('jeu vid') ||
        cat.contains('jeux vid') ||
        cat.contains('virtuelle') ||
        cat.contains('manga') ||
        cat.contains('comics') ||
        cat.contains('cosplay') ||
        cat.contains('figurine')) {
      return _defaultGamingVideo;
    }

    // Culture (les keywords sont tous sans accents — _normalizeForMatch a
    // deja strippe les accents de cat). 'histoire'/'science'/'culture' sont
    // les labels MuseumVenue, 'biblio' couvre bibliotheque + bibliotheques.
    if (cat.contains('cinema') ||
        cat.contains('cine') ||
        cat.contains('theatre') ||
        cat.contains('theatr') ||
        cat.contains('musee') ||
        cat.contains('galerie') ||
        cat.contains('opera') ||
        cat.contains('biblio') ||
        cat.contains('mediatheque') ||
        cat.contains('exposition') ||
        cat.contains('expo') ||
        cat.contains('monument') ||
        cat.contains('patrimoine') ||
        cat.contains('concert') ||
        cat.contains('danse') ||
        cat.contains('histoire') ||
        cat.contains('science') ||
        cat.contains('culture') ||
        cat.contains('art')) {
      return _defaultCultureVideo;
    }

    // Food
    if (cat.contains('restaurant') ||
        cat.contains('brasserie') ||
        cat.contains('pizzeria') ||
        cat.contains('sushi') ||
        cat.contains('bistro') ||
        cat.contains('food') ||
        cat.contains('cafe')) {
      return defaultFoodVideo;
    }

    // Repli universel (mode Day + categories non typees).
    return _defaultGenericVideo;
  }

  static String _buildShareTextFor(CommerceModel commerce) {
    final buffer = StringBuffer();
    buffer.writeln(commerce.nom);
    if (commerce.adresse.isNotEmpty) buffer.writeln(commerce.adresse);
    if (commerce.horaires.isNotEmpty) {
      buffer.writeln('Horaires: ${commerce.horaires}');
    }
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  static IconData _categoryIcon(String category) {
    final cat = _normalize(category);
    if (cat.contains('restaurant') || cat.contains('food')) return Icons.restaurant;
    if (cat.contains('bar') || cat.contains('pub') || cat.contains('nuit')) return Icons.local_bar;
    if (cat.contains('club') || cat.contains('discotheque')) return Icons.nightlife;
    if (cat.contains('hotel')) return Icons.hotel;
    if (cat.contains('cinema')) return Icons.movie;
    if (cat.contains('theatre')) return Icons.theater_comedy;
    if (cat.contains('musee') || cat.contains('galerie')) return Icons.museum;
    if (cat.contains('fitness') || cat.contains('sport')) return Icons.fitness_center;
    if (cat.contains('piscine') || cat.contains('natation')) return Icons.pool;
    if (cat.contains('bowling')) return Icons.sports;
    if (cat.contains('gaming') || cat.contains('arcade') || cat.contains('jeux')) return Icons.sports_esports;
    if (cat.contains('manga') || cat.contains('comics') || cat.contains('boutique')) return Icons.store;
    if (cat.contains('escape')) return Icons.lock;
    if (cat.contains('laser')) return Icons.flash_on;
    if (cat.contains('parc')) return Icons.park;
    if (cat.contains('ferme')) return Icons.nature;
    if (cat.contains('patinoire')) return Icons.ice_skating;
    if (cat.contains('bibliotheque') || cat.contains('mediatheque')) return Icons.menu_book;
    if (cat.contains('chicha')) return Icons.smoking_rooms;
    if (cat.contains('epicerie') || cat.contains('tabac')) return Icons.store;
    if (cat.contains('apero')) return Icons.liquor;
    if (cat.contains('vr') || cat.contains('virtuelle')) return Icons.vrpano;
    if (cat.contains('cosplay') || cat.contains('figurine')) return Icons.emoji_objects;
    return Icons.place;
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.geist(
              fontSize: 11,
              color: AppColors.textDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLikeIcon(WidgetRef ref) {
    final likeId = 'night_${commerce.nom}';
    final isLiked = ref.watch(likesProvider).contains(likeId);
    return GestureDetector(
      onTap: () => ref.read(likesProvider.notifier).toggle(
        likeId,
        meta: LikeMetadata(
          title: commerce.nom,
          imageUrl: commerce.photo.isNotEmpty ? commerce.photo : null,
          category: commerce.categorie,
        ),
      ),
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        size: 16,
        color: isLiked ? AppColors.magenta : AppColors.textFaint,
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// Petite pastille note moyenne + count, affichee a droite du nom du commerce.
class _RatingPill extends StatelessWidget {
  final CommerceReviewSummary summary;

  const _RatingPill({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFC107)),
        const SizedBox(width: 2),
        Text(
          summary.avgRating.toStringAsFixed(1),
          style: GoogleFonts.geist(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '(${summary.reviewCount})',
          style: GoogleFonts.geist(
            fontSize: 9,
            color: AppColors.textFaint,
          ),
        ),
      ],
    );
  }
}

/// Petit bouton "Revendiquer" qui ouvre le sheet de revendication.
class _ClaimButton extends StatelessWidget {
  final String commerceName;
  final String? sourceTable;
  final int? sourceId;
  final bool small;

  const _ClaimButton.small({
    required this.commerceName,
    this.sourceTable,
    this.sourceId,
  }) : small = true;
  const _ClaimButton({
    required this.commerceName,
    this.sourceTable,
    this.sourceId,
  }) : small = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ClaimVenueSheet.show(
        context,
        commerceName,
        sourceTable: sourceTable,
        sourceId: sourceId,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 10,
          vertical: small ? 2 : 4,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          ),
          borderRadius: BorderRadius.circular(small ? 6 : 10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: small ? 8 : 12, color: Colors.white),
            SizedBox(width: small ? 2 : 4),
            Text(
              'Revendiquer',
              style: TextStyle(
                fontSize: small ? 7 : 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de revendication d'un etablissement.
class ClaimVenueSheet extends ConsumerStatefulWidget {
  final String commerceName;
  final String? sourceTable;
  final int? sourceId;

  const ClaimVenueSheet({
    super.key,
    required this.commerceName,
    this.sourceTable,
    this.sourceId,
  });

  static void show(
    BuildContext context,
    String commerceName, {
    String? sourceTable,
    int? sourceId,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimVenueSheet(
        commerceName: commerceName,
        sourceTable: sourceTable,
        sourceId: sourceId,
      ),
    );
  }

  @override
  ConsumerState<ClaimVenueSheet> createState() => _ClaimVenueSheetState();
}

class _ClaimVenueSheetState extends ConsumerState<ClaimVenueSheet> {
  final _siretController = TextEditingController();
  final _urlController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  bool _codeMode = false;
  bool _codeSubmitting = false;
  String? _codeError;

  @override
  void dispose() {
    _siretController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Entrez le code recu par MaCity.');
      return;
    }
    if (widget.sourceTable == null || widget.sourceId == null) {
      setState(() => _codeError =
          'Fiche non identifiee. Reouvrez la depuis la liste pour revendiquer.');
      return;
    }
    setState(() {
      _codeSubmitting = true;
      _codeError = null;
    });
    try {
      await ProVenueService().claimWithMacityCode(
        sourceTable: widget.sourceTable!,
        sourceId: widget.sourceId!,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _codeSubmitting = false;
        _submitted = true;
      });
    } on ProClaimCodeError catch (e) {
      if (!mounted) return;
      setState(() {
        _codeSubmitting = false;
        _codeError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _codeSubmitting = false;
        _codeError = 'Erreur reseau, reessaie.';
      });
    }
  }

  /// Appelle l'edge function validate-siret pour verifier le SIRET contre
  /// l'API SIRENE. Retourne null si valide, sinon un message d'erreur.
  Future<String?> _validateSiret(String siret) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '${SupabaseConfig.supabaseUrl}/functions/v1/',
        receiveTimeout: const Duration(seconds: 10),
      ));
      dio.interceptors.add(SupabaseInterceptor());
      final res = await dio.post('validate-siret', data: {'siret': siret});
      final data = res.data as Map<String, dynamic>;
      if (data['valid'] == true) return null;
      return (data['reason'] as String?) ?? 'SIRET non valide';
    } catch (e) {
      debugPrint('[ClaimVenue] SIRET validation error: $e');
      return 'Impossible de verifier le SIRET. Reessaie.';
    }
  }

  Future<void> _submit() async {
    final siret = _siretController.text.trim();
    final proof = _urlController.text.trim();
    final email = _emailController.text.trim();
    final telephone = _telephoneController.text.trim();
    if (siret.isEmpty && proof.isEmpty) return;
    if (email.isEmpty && telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indique au moins un email ou un telephone pour te recontacter.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      // Si SIRET fourni, on le valide d'abord contre l'API SIRENE.
      if (siret.isNotEmpty) {
        final err = await _validateSiret(siret);
        if (err != null) {
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('SIRET invalide : $err')),
            );
          }
          return;
        }
      }

      final userId = await UserIdentityService.getUserId();
      await VenuesSupabaseService().claimVenue(
        venueName: widget.commerceName,
        proId: userId,
        siret: siret,
        proofUrl: proof,
        message: _messageController.text.trim(),
        email: email,
        telephone: telephone,
        sourceTable: widget.sourceTable,
        sourceId: widget.sourceId,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
        });
      }
    } on DioException catch (e) {
      // 409 = anti-spam UNIQUE (user_id, venue_name) deja existant.
      if (e.response?.statusCode == 409) {
        if (mounted) {
          setState(() {
            _loading = false;
            _submitted = true;
          });
        }
        return;
      }
      debugPrint('[ClaimVenue] dio error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur reseau, reessaie.')),
        );
      }
    } catch (e) {
      debugPrint('[ClaimVenue] error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: _submitted
            ? _buildSuccess()
            : (_codeMode ? _buildCodeForm() : _buildForm()),
      ),
    );
  }

  Widget _buildCodeForm() {
    final proStatus = ref.watch(proAuthProvider).status;
    final isProSignedIn = proStatus == ProAuthStatus.approved ||
        proStatus == ProAuthStatus.pendingApproval;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF7B2D8E)),
              onPressed: () => setState(() {
                _codeMode = false;
                _codeError = null;
              }),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'J\'ai un code MaCity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez le code unique envoye par MaCity pour ${widget.commerceName}. '
          'Apres validation, vous pourrez modifier la fiche (photos + video) depuis votre espace pro.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        if (!isProSignedIn) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFFEF6C00), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connectez-vous a votre compte pro avant d\'utiliser le code.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ProLoginSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2D8E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Se connecter pro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ] else ...[
          _buildField('Code MaCity', _codeController, 'Ex: ABC-12345',
              TextInputType.text),
          if (_codeError != null) ...[
            const SizedBox(height: 8),
            Text(_codeError!,
                style: TextStyle(
                    fontSize: 12, color: Colors.red.shade700)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _codeSubmitting ? null : _submitCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2D8E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _codeSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Valider le code',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    final viaCode = _codeMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, size: 56, color: Color(0xFF4CAF50)),
        const SizedBox(height: 16),
        Text(
          viaCode ? 'Fiche verifiee !' : 'Demande envoyee !',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          viaCode
              ? 'Votre compte pro est associe a "${widget.commerceName}". Vous pouvez maintenant modifier la fiche depuis "Mon compte" → "Modifier ma fiche".'
              : 'Votre demande de revendication pour "${widget.commerceName}" a ete soumise. Vous serez notifie une fois approuvee.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2D8E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.store_outlined, size: 20, color: Color(0xFF7B2D8E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Revendiquer "${widget.commerceName}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Vous etes le proprietaire ? Remplissez ce formulaire pour verifier votre etablissement et obtenir le badge verifie.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        // Raccourci : si MaCity a fourni un code apres verification hors-app,
        // le pro peut le saisir directement pour skip le check SIRET.
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _codeMode = true;
            _codeError = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2D8E), Color(0xFF9B4DCA)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'J\'ai un code MaCity',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('ou', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          ],
        ),
        const SizedBox(height: 12),
        _buildField('SIRET ou numero RNA', _siretController, 'SIRET (14 chiffres) ou W + 9 chiffres (asso)', TextInputType.text),
        const SizedBox(height: 12),
        _buildField('Site web ou reseau social', _urlController, 'https://...', TextInputType.url),
        const SizedBox(height: 12),
        _buildField('Email de contact', _emailController, 'pour te recontacter', TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildField('Telephone (optionnel si email)', _telephoneController, '06 12 34 56 78', TextInputType.phone),
        const SizedBox(height: 12),
        _buildField('Message (optionnel)', _messageController, 'Informations complementaires...', TextInputType.multiline, maxLines: 3),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2D8E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Envoyer la demande', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, TextInputType type, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7B2D8E))),
          ),
        ),
      ],
    );
  }
}
