import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/widgets/fullscreen_image_viewer.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart' show ClaimVenueSheet;
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/reviews/presentation/reviews_section.dart';

/// Fiche detail generique ouverte au tap sur une carte (commerce, event, match, venue).
/// Affichee en popup plein ecran avec pochette en fond et infos overlayees.
class ItemDetailSheet extends ConsumerWidget {
  final String title;
  final String emoji;
  final String? imageAsset;
  final String? imageUrl;
  final String? videoUrl;
  final List<DetailInfoItem> infos;
  final DetailAction? primaryAction;
  /// Second gros bouton rendu juste en dessous du primaryAction. Optionnel.
  /// Style outlined pour ne pas concurrencer visuellement le primary.
  final DetailAction? secondaryButton;
  final List<DetailAction> secondaryActions;
  final String shareText;
  final String? likeId;
  final Widget? extraContent;
  final double imageHeightFraction;
  final bool isVerified;
  final bool isPartner;
  /// Libellé du badge partenaire (adapté à la rubrique). Défaut restaurant.
  final String partnerLabel;
  final List<String> photoGallery;
  final ReviewsTarget? reviewsTarget;
  /// Description multi-paragraphes affichee sous la gallery (au-dessus des
  /// info rows). Vide = pas de bloc rendu.
  final String description;
  /// Source (table + id) propagee au bouton "Revendiquer". Permet a
  /// l'admin d'identifier la fiche exacte (sport_venues, venues, etc.).
  /// Si null, le claim est cree avec juste le nom (mode legacy).
  final String? claimSourceTable;
  final int? claimSourceId;

  const ItemDetailSheet({
    super.key,
    required this.title,
    this.emoji = '',
    this.imageAsset,
    this.imageUrl,
    this.videoUrl,
    this.infos = const [],
    this.primaryAction,
    this.secondaryButton,
    this.secondaryActions = const [],
    this.shareText = '',
    this.likeId,
    this.extraContent,
    this.imageHeightFraction = 1.0,
    this.isVerified = false,
    this.isPartner = false,
    this.partnerLabel = 'Restaurant partenaire',
    this.photoGallery = const [],
    this.reviewsTarget,
    this.description = '',
    this.claimSourceTable,
    this.claimSourceId,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  /// Ouvre le popup plein ecran.
  static void show(BuildContext context, ItemDetailSheet sheet) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked =
        likeId != null ? ref.watch(likesProvider).contains(likeId) : false;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    final hasImage = hasVideo ||
        (imageAsset != null && imageAsset!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // ── Fond : image ou gradient ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: hasImage
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: imageHeightFraction < 1.0
                                    ? screenHeight * 0.85 * imageHeightFraction
                                    : double.infinity,
                              ),
                              child: hasVideo
                                  ? _DetailVideoPlayer(videoUrl: videoUrl!)
                                  : GestureDetector(
                                      // Tap sur l'affiche -> plein ecran zoomable.
                                      onTap: () => _showFullAffiche(context),
                                      child: _buildImage(),
                                    ),
                            )
                          : _buildGradientFallback(),
                    ),
                  ],
                ),

                // ── Gradient overlay ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.55, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenu overlay ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermer
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Emoji header retire (decision design : pas d'emoticon
                    // dans les fiches detail). Param `emoji` conserve pour
                    // compat callers mais ignore.

                    if (imageHeightFraction >= 1.0) const Spacer(),

                    // ── Infos en bas ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Titre + badge verifie
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: isVerified
                                    ? const VerifiedBadge()
                                    : GestureDetector(
                                        onTap: () => ClaimVenueSheet.show(
                                          context,
                                          title,
                                          sourceTable: claimSourceTable,
                                          sourceId: claimSourceId,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified_outlined, size: 13, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Revendiquer', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),

                          if (isPartner) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC79A3E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 13, color: Color(0xFF2A1E06)),
                                  const SizedBox(width: 5),
                                  Text(partnerLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2A1E06),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      )),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Description multi-paragraphes
                          if (description.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Photo gallery (grille 3x2)
                          if (photoGallery.isNotEmpty) ...[
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              children: [
                                for (int i = 0; i < photoGallery.length && i < 6; i++)
                                  GestureDetector(
                                    onTap: () => _showFullPhoto(context, photoGallery[i]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24, width: 0.5),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: photoGallery[i].startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: photoGallery[i],
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: Colors.white12),
                                              errorWidget: (_, __, ___) => Container(
                                                color: Colors.white12,
                                                child: const Icon(Icons.photo_outlined, color: Colors.white30, size: 20),
                                              ),
                                            )
                                          : Image.asset(photoGallery[i], fit: BoxFit.cover),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Info rows
                          ...infos.map(
                            (info) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    info.icon,
                                    size: 15,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      info.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Contenu supplementaire (ex: programmation) ──
                          if (extraContent != null) ...[
                            const SizedBox(height: 10),
                            extraContent!,
                          ],

                          // ── Section Avis (si commerce) ──
                          if (reviewsTarget != null) ...[
                            const SizedBox(height: 14),
                            ReviewsSection(target: reviewsTarget!),
                          ],

                          const SizedBox(height: 14),

                          // Primary action (Site web / Billetterie) en premier
                          if (primaryAction != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: primaryAction!.disabled
                                    ? null
                                    : () => primaryAction!.onTap != null
                                        ? primaryAction!.onTap!()
                                        : _openUrl(primaryAction!.url),
                                icon: Icon(primaryAction!.icon, size: 18),
                                label: Text(
                                  primaryAction!.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.white.withValues(alpha: 0.12),
                                  disabledForegroundColor:
                                      Colors.white.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Bouton secondaire en gros, style outlined.
                          if (secondaryButton != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: secondaryButton!.disabled
                                    ? null
                                    : () => secondaryButton!.onTap != null
                                        ? secondaryButton!.onTap!()
                                        : _openUrl(secondaryButton!.url),
                                icon: Icon(secondaryButton!.icon, size: 18),
                                label: Text(
                                  secondaryButton!.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── Boutons actions secondaires ──
                          // Force tous les pills sur une seule ligne via
                          // Expanded (chaque pill prend 1/Npart egal de la
                          // largeur). _buildPillButton centre son contenu pour
                          // que le rendu reste lisible quand la largeur est
                          // imposee depuis l'exterieur.
                          Builder(builder: (_) {
                            final pills = <Widget>[
                              if (likeId != null)
                                _buildPillButton(
                                  icon: isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  label: isLiked ? 'Aime' : 'Aimer',
                                  color:
                                      isLiked ? Colors.red : Colors.white,
                                  onTap: () => ref
                                      .read(likesProvider.notifier)
                                      .toggle(
                                        likeId!,
                                        meta: LikeMetadata(
                                          title: title,
                                          imageUrl: imageUrl,
                                          assetImage: imageAsset,
                                        ),
                                      ),
                                ),
                              if (shareText.isNotEmpty)
                                _buildPillButton(
                                  icon: Icons.share_outlined,
                                  label: 'Partager',
                                  color: Colors.white,
                                  onTap: () => Share.share(shareText),
                                ),
                              ...secondaryActions.map(
                                (action) => _buildPillButton(
                                  icon: action.icon,
                                  label: action.label,
                                  color: Colors.white,
                                  onTap: () => action.onTap != null
                                      ? action.onTap!()
                                      : _openUrl(action.url),
                                ),
                              ),
                            ];
                            return Row(
                              children: [
                                for (var i = 0; i < pills.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(child: pills[i]),
                                ],
                              ],
                            );
                          },),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover, width: double.infinity)
            : _buildGradientFallback(),
        errorWidget: (_, __, ___) => imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover, width: double.infinity, cacheWidth: 300)
            : _buildGradientFallback(),
      );
    }
    return Image.asset(
      imageAsset!,
      fit: BoxFit.cover,
      cacheWidth: 300,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _buildGradientFallback(),
    );
  }

  /// Ouvre l'affiche principale en plein ecran, zoomable (pinch) et
  /// deplacable. Tap n'importe ou (ou la croix) pour fermer.
  void _showFullAffiche(BuildContext context) {
    showFullscreenImage(
      context,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
        ),
      ),
      // Emoji fallback retire — fond gradient seul.
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        // Center sans widthFactor : le pill est toujours wrappé dans Expanded
        // (forcage 1 ligne pour les 3 actions), donc Center recoit des
        // contraintes bornees et centre le Row interne au lieu de coller a
        // gauche.
        child: Center(
          heightFactor: 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String photoUrl) {
    final index = photoGallery.indexOf(photoUrl);
    final controller = PageController(initialPage: index >= 0 ? index : 0);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => Stack(
        children: [
          // Swipeable photos
          PageView.builder(
            controller: controller,
            itemCount: photoGallery.length,
            itemBuilder: (_, i) {
              final photo = photoGallery[i];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: photo.startsWith('http')
                          ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.contain)
                          : Image.asset(photo, fit: BoxFit.contain),
                    ),
                  ),
                ),
              );
            },
          ),
          // Bouton fermer
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Indicateur
          if (photoGallery.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: StatefulBuilder(
                  builder: (_, setState) {
                    controller.addListener(() {
                      if (controller.page != null) setState(() {});
                    });
                    final current = (controller.page ?? index).round() + 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$current / ${photoGallery.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Sur Android, Instagram intercepte les liens instagram.com
    // et ouvre le feed au lieu du profil. On force l'ouverture
    // dans le navigateur via un Intent explicite.
    if (Platform.isAndroid && uri.host.contains('instagram.com')) {
      try {
        const channel = MethodChannel('com.macity.app/browser');
        await channel.invokeMethod('openInBrowser', {'url': url});
        return;
      } catch (_) {
        // Fallback si le channel natif n'existe pas.
      }
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Impossible d\'ouvrir le lien: $e');
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Impossible d\'ouvrir le lien: $e');
      }
    }
  }
}

class DetailInfoItem {
  final IconData icon;
  final String text;
  const DetailInfoItem(this.icon, this.text);
}

class DetailAction {
  final IconData icon;
  final String label;
  /// URL a lancer via url_launcher. Ignore si [onTap] est fourni.
  final String url;
  /// Callback custom (prend le pas sur [url]). Utile pour ouvrir une sheet
  /// interne au lieu de naviguer hors de l'app.
  final VoidCallback? onTap;
  /// Si true, le bouton est rendu grise et non-cliquable. Utile pour
  /// les CTAs conditionnels (ex: "Reserver" si le resto n'a pas de claim).
  final bool disabled;
  const DetailAction({
    required this.icon,
    required this.label,
    this.url = '',
    this.onTap,
    this.disabled = false,
  });
}

/// Video player teaser dans le detail d'un etablissement (15s max, looping, mute toggle).
class _DetailVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _DetailVideoPlayer({required this.videoUrl});

  @override
  State<_DetailVideoPlayer> createState() => _DetailVideoPlayerState();
}

class _DetailVideoPlayerState extends State<_DetailVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(1.0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C))),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const ColoredBox(
                color: Colors.black26,
                child: Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 40)),
              ),
            // Mute toggle
            Positioned(
              bottom: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _muted = !_muted;
                    _controller.setVolume(_muted ? 0 : 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Badge "Teaser"
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TEASER',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
