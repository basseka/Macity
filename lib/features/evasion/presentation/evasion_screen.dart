import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/data/inspiration_service.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/evasion/domain/evasion_venue.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/evasion/state/evasion_venues_provider.dart';

/// Écran « Évasion » — hub des domaines / châteaux de séjour, calqué sur les
/// autres rubriques : grand hero vidéo (mode `tourisme`), puis sections
/// « Nos partenaires », « Inspirations du moment » et « Affinez votre
/// recherche » (filtres par temps de trajet À 1h / À 2h / À 3h).
///
/// Écran autonome (hors ShellRoute) : gère son propre chrome. Chaque section se
/// masque d'elle-même quand elle n'a rien à afficher.
class EvasionScreen extends ConsumerStatefulWidget {
  const EvasionScreen({super.key});

  @override
  ConsumerState<EvasionScreen> createState() => _EvasionScreenState();
}

class _EvasionScreenState extends ConsumerState<EvasionScreen> {
  static const _bg = Color(0xFFF6F1E6); // crème (RubriqueTheme.bg)
  static const _ink = Color(0xFF0B1410);
  static const _muted = Color(0xFF6B6F66);
  static const _amber = Color(0xFFB45309);

  VideoPlayerController? _video;
  String? _videoUrl;
  bool _videoError = false;

  /// Temps de trajet max sélectionné (1/2/3), null = tous. 2e tap = désélection.
  int? _maxHours;

  void _initVideo(String url) {
    _videoUrl = url;
    _videoError = false;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    c.setLooping(true);
    c.setVolume(0);
    c.initialize().then((_) {
      if (mounted) {
        c.play();
        setState(() {});
      }
    }).catchError((_) {
      if (mounted) setState(() => _videoError = true);
    });
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = ref.watch(evasionBannerVideoProvider).asData?.value;
    if (banner != null && _videoUrl != banner.videoUrl) {
      _video?.dispose();
      _video = null;
      _initVideo(banner.videoUrl);
    }

    final all = ref.watch(evasionVenuesProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _hero(),
          const SizedBox(height: 18),
          ..._partnersSection(all),
          ..._inspirationsSection(),
          ..._refineSection(all),
        ],
      ),
    );
  }

  // ─── Nos partenaires ──────────────────────────────────────────────────
  /// Vitrine en tête : uniquement les domaines marqués partenaire
  /// (is_partner). Si aucun n'est coché, la section n'est pas affichée.
  /// La liste complète reste dans « Affinez votre recherche ».
  List<Widget> _partnersSection(List<EvasionVenue>? all) {
    if (all == null || all.isEmpty) return const [];
    final partners = all.where((v) => v.isPartner).toList();
    if (partners.isEmpty) return const [];
    return [
      _sectionHeader('Nos partenaires'),
      _venueCarousel(partners),
      const SizedBox(height: 20),
    ];
  }

  // ─── Inspirations du moment ───────────────────────────────────────────
  List<Widget> _inspirationsSection() {
    final items =
        ref.watch(inspirationsProvider('evasion')).valueOrNull ?? const [];
    if (items.isEmpty) return const [];
    return [
      _sectionHeader('Inspirations du moment'),
      SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _inspirationCard(items[i]),
        ),
      ),
      const SizedBox(height: 4),
    ];
  }

  // ─── Affinez votre recherche ──────────────────────────────────────────
  List<Widget> _refineSection(List<EvasionVenue>? all) {
    if (all == null) {
      return const [
        SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(color: _amber, strokeWidth: 2),
          ),
        ),
      ];
    }
    if (all.isEmpty) return const [];
    final list = _maxHours == null
        ? all
        : all.where((v) => v.travelTimeH <= _maxHours!).toList();
    return [
      _sectionHeader('Affinez votre recherche'),
      SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          children: [
            for (final h in const [1, 2, 3]) _chip('À ${h}h', h),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Text('Aucune adresse pour ce filtre.',
              style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        )
      else
        _venueCarousel(list),
    ];
  }

  Widget _chip(String label, int hours) {
    final active = _maxHours == hours;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _maxHours = active ? null : hours),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _amber : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: active ? _amber : const Color(0x1A0B1410),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : _ink,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Carrousel de domaines (carte poster, calquée sur Food) ───────────
  Widget _venueCarousel(List<EvasionVenue> list) {
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _card(list, i),
      ),
    );
  }

  /// Ouvre la fiche détail riche (galerie + teaser + infos), en pager swipable
  /// sur toute la liste — comme Food.
  void _openVenue(List<EvasionVenue> list, int index) {
    CommerceRowCard.openDetail(
      context,
      list[index].toCommerce(),
      siblings: list.map((v) => v.toCommerce()).toList(),
      index: index,
    );
  }

  /// Carte poster (image plein cadre + dégradé + nom en bas), identique aux
  /// cartes restaurant de Food : largeur 160, coins rCard, ombre carte.
  Widget _card(List<EvasionVenue> list, int i) {
    final v = list[i];
    final hasPhoto = v.photo.startsWith('http');
    return GestureDetector(
      onTap: () => _openVenue(list, i),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FoodTokens.rCard),
          border: Border.all(color: FoodTokens.hairline, width: 1),
          boxShadow: FoodTokens.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: v.photo,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFF2A332D)),
                errorWidget: (_, __, ___) => _cardGradient(),
              )
            else
              _cardGradient(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x59000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.0, 0.28, 0.45, 1.0],
                ),
              ),
            ),
            // Badge temps de trajet.
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xC70B1410),
                  borderRadius: BorderRadius.circular(FoodTokens.rPill),
                ),
                child: Text('À ${v.travelTimeH}h',
                    style: FoodTokens.tinyTag(
                        color: Colors.white,
                        size: 8,
                        spacing: 0.3,
                        w: FontWeight.w700)),
              ),
            ),
            // Badge partenaire (même style que les cartes poster Food),
            // placé à droite car le badge trajet occupe déjà la gauche.
            if (v.isPartner)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC79A3E),
                    borderRadius: BorderRadius.circular(FoodTokens.rPill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80C79A3E),
                        blurRadius: 6,
                        spreadRadius: -2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 6, color: Color(0xFF2A1E06)),
                      const SizedBox(width: 2),
                      Text('PARTENAIRE',
                          style: FoodTokens.tinyTag(
                            color: const Color(0xFF2A1E06),
                            size: 5,
                            spacing: 0.5,
                            w: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(v.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.cardName()),
                  if (v.ville.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(v.ville,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.meta(
                            color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dégradé ambre de repli (équivalent Évasion du _CardGradient de Food).
  Widget _cardGradient() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF92400E), Color(0xFFD97706)],
          ),
        ),
      );

  // ─── Carte Inspiration (identique à Food : 124 px, fond sombre) ───────
  Widget _inspirationCard(Inspiration insp) {
    final hasSite = insp.siteUrl.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => _openLink(insp.siteUrl),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 124,
        decoration: BoxDecoration(
          color: FoodTokens.dark,
          borderRadius: BorderRadius.circular(FoodTokens.rInspiration),
          boxShadow: FoodTokens.mini,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 62,
              child: insp.photoUrl.trim().isEmpty
                  ? _inspGradient()
                  : CachedNetworkImage(
                      imageUrl: insp.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _inspGradient(),
                      errorWidget: (_, __, ___) => _inspGradient(),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insp.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.meta(
                            color: Colors.white, w: FontWeight.w600)),
                    if (insp.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(insp.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FoodTokens.tinyTag(
                            color: Colors.white.withValues(alpha: 0.62),
                            size: 9.5,
                            spacing: 0,
                            w: FontWeight.w400,
                          )),
                    ],
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: hasSite ? () => _openLink(insp.siteUrl) : null,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FoodTokens.teal,
                          ),
                          child: const Icon(Icons.arrow_outward_rounded,
                              size: 11, color: Color(0xFF08221C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inspGradient() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A1F14), Color(0xFF7A3B22)],
          ),
        ),
      );

  Future<void> _openLink(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── En-tête de section (mêmes polices que Food) ──────────────────────
  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Text(title, style: FoodTokens.sectionHeader()),
      );

  // ─── Hero vidéo ───────────────────────────────────────────────────────
  Widget _hero() {
    final topPad = MediaQuery.of(context).padding.top;
    final c = _video;
    final ready = c != null &&
        c.value.isInitialized &&
        !_videoError &&
        c.value.size.width > 0;

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF92400E), Color(0xFFD97706)],
                ),
              ),
            ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x73000000),
                      Color(0xD90B1410),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad + 8,
            left: 18,
            child: GestureDetector(
              onTap: () => context.go('/home'),
              behavior: HitTestBehavior.opaque,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.96),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.chevron_left,
                        size: 17, color: _ink),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Évasion.',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                    height: 0.95,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    'Escapades et week-ends autour de chez vous.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.3,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
