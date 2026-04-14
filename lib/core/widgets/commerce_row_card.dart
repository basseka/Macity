import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Carte commerce en ligne : image a gauche, infos a droite.
class CommerceRowCard extends ConsumerWidget {
  final CommerceModel commerce;
  final String? imageAsset;

  const CommerceRowCard({
    super.key,
    required this.commerce,
    this.imageAsset,
  });

  /// Retourne la photo DB, l'asset explicite, ou la pochette par defaut.
  String? _resolveImage() {
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
    if (cat.contains('coquin')) return 'assets/images/pochette_coquin.png';
    if (cat.contains('strip')) return 'assets/images/pochette_strip.png';
    if (cat.contains('spicy')) return 'assets/images/pochette_spicy.png';
    if (cat.contains('club') || cat.contains('discotheque')) return 'assets/images/pochette_discotheque.png';
    if (cat.contains('bar') && cat.contains('cocktail')) return 'assets/images/pochette_barcocktail.png';
    if (cat.contains('pub')) return 'assets/images/sc_pub.jpg';
    if (cat.contains('bar') && cat.contains('nuit')) return 'assets/images/pochette_default.jpg';
    if (cat.contains('chicha')) return 'assets/images/pochette_chicha.png';
    if (cat.contains('hotel')) return 'assets/images/sc_hotel.jpg';
    if (cat.contains('epicerie')) return 'assets/images/pochette_epicerie.jpg';
    if (cat.contains('restaurant')) return 'assets/images/pochette_restaurant.jpg';
    if (cat.contains('cinema')) return 'assets/images/pochette_cinema.png';
    if (cat.contains('musee')) return 'assets/images/pochette_musee.png';
    if (cat.contains('theatre')) return 'assets/images/pochette_theatre.png';
    if (cat.contains('fitness') || cat.contains('sport')) return 'assets/images/pochette_fitnesspark.png';
    if (cat.contains('natation') || cat.contains('piscine')) return 'assets/images/pochette_natation.jpg';
    if (cat.contains('gaming') || cat.contains('arcade')) return 'assets/images/pochette_gaming.jpg';
    if (cat.contains('yoga')) return 'assets/images/pochette_yoga.jpg';
    if (cat.contains('bowling')) return 'assets/images/pochette_bowling.png';
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

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Pochette image a gauche ──
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
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
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: modeTheme.primaryDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (commerce.isVerified)
                          const VerifiedBadge.small()
                        else
                          _ClaimButton.small(commerceName: commerce.nom),
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
                          Colors.grey.shade400,
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

  void _openDetail(BuildContext context) {
    final image = _resolveImage();
    final isNetwork = image != null && image.startsWith('http');
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: commerce.nom,
        emoji: '',
        imageAsset: isNetwork ? null : image,
        imageUrl: isNetwork ? image : null,
        videoUrl: commerce.videoUrl.isNotEmpty
            ? commerce.videoUrl
            : _defaultVideoUrl(),
        likeId: 'night_${commerce.nom}',
        isVerified: commerce.isVerified,
        photoGallery: _buildPhotoGallery(),
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
        shareText: _buildShareText(),
      ),
    );
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

  /// Construit la galerie photo pour le detail.
  List<String> _buildPhotoGallery() {
    // Si le proprio a revendique, ses propres photos seront ici
    // TODO: charger les photos du proprio depuis la DB
    final photos = <String>[];
    if (commerce.photo.isNotEmpty && commerce.photo.startsWith('http')) {
      photos.add(commerce.photo);
    }

    // Si pas assez de photos et non verifie → photos generiques par categorie
    if (!commerce.isVerified && photos.length < 6) {
      final cat = commerce.categorie.toLowerCase();
      List<String>? defaults;
      if (cat.contains('club') || cat.contains('discotheque')) {
        defaults = _defaultClubPhotos;
      } else if (cat.contains('restaurant') || cat.contains('food') || cat.contains('brunch') || cat.contains('salon de the') || cat.contains('buffet') || cat.contains('guinguette')) {
        defaults = _defaultRestaurantPhotos;
      }
      if (defaults != null) {
        for (final p in defaults) {
          if (photos.length >= 6) break;
          if (!photos.contains(p)) photos.add(p);
        }
      }
    }

    return photos;
  }

  /// Video par defaut pour les clubs/discotheques non revendiques.
  static const _defaultClubVideo =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/user-events/teaser_disco_1.mp4';

  String? _defaultVideoUrl() {
    // Seulement pour les clubs/discotheques non revendiques
    if (commerce.isVerified) return null;
    final cat = commerce.categorie.toLowerCase();
    if (cat.contains('club') || cat.contains('discotheque')) {
      return _defaultClubVideo;
    }
    return null;
  }

  String _buildShareText() {
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
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
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
        color: isLiked ? Colors.red : Colors.grey.shade400,
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

/// Petit bouton "Revendiquer" qui ouvre le sheet de revendication.
class _ClaimButton extends StatelessWidget {
  final String commerceName;
  final bool small;

  const _ClaimButton.small({required this.commerceName}) : small = true;
  const _ClaimButton({required this.commerceName}) : small = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ClaimVenueSheet.show(context, commerceName),
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
class ClaimVenueSheet extends StatefulWidget {
  final String commerceName;

  const ClaimVenueSheet({super.key, required this.commerceName});

  static void show(BuildContext context, String commerceName) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimVenueSheet(commerceName: commerceName),
    );
  }

  @override
  State<ClaimVenueSheet> createState() => _ClaimVenueSheetState();
}

class _ClaimVenueSheetState extends State<ClaimVenueSheet> {
  final _siretController = TextEditingController();
  final _urlController = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _siretController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_siretController.text.isEmpty && _urlController.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      final userId = await UserIdentityService.getUserId();
      await VenuesSupabaseService().claimVenue(
        venueName: widget.commerceName,
        proId: userId,
        siret: _siretController.text.trim(),
        proofUrl: _urlController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
        });
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
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, size: 56, color: Color(0xFF4CAF50)),
        const SizedBox(height: 16),
        const Text('Demande envoyee !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Votre demande de revendication pour "${widget.commerceName}" a ete soumise. Vous serez notifie une fois approuvee.',
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
        const SizedBox(height: 16),
        _buildField('Numero SIRET', _siretController, 'Ex: 123 456 789 00012', TextInputType.number),
        const SizedBox(height: 12),
        _buildField('Site web ou reseau social', _urlController, 'https://...', TextInputType.url),
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
