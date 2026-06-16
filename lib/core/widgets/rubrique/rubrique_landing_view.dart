import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/data/inspiration_service.dart';
import 'package:pulz_app/core/widgets/commerce_pager_view.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Palette + typo paramétrables d'une rubrique (réutilise le design Food
/// mais avec la couleur signature de chaque rubrique).
class RubriqueTheme {
  final Color accent; // CTA / chip actif / Voir tout
  final Color accent2; // dégradé secondaire (chip actif, FAB)
  final Color tealAccent; // badge / mini-flèche inspiration

  const RubriqueTheme({
    required this.accent,
    required this.accent2,
    this.tealAccent = const Color(0xFF2BAB9A),
  });

  static const bg = Color(0xFFF6F1E6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0B1410);
  static const muted = Color(0xFF6B6F66);
  static const stroke = Color(0x1A0B1410);
  static const hairline = Color(0x0F0B1410);
  static const dark = Color(0xFF142019);
  static const pink = Color(0xFFE64A8F);
  static const red = Color(0xFFFF4D5E);

  static TextStyle heroTitle() => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -1,
        height: 0.95,
        color: Colors.white,
      );

  static TextStyle sectionHeader({Color color = ink, double fontSize = 14}) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.1,
        color: color,
      );

  static TextStyle cardName({Color color = Colors.white}) =>
      GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        height: 1.05,
        color: color,
      );

  static TextStyle body({Color? color}) => GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color ?? muted,
      );

  static TextStyle chip({required Color color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.poppins(
          fontSize: 10, fontWeight: w, height: 1, color: color);

  static TextStyle meta({Color? color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.poppins(
          fontSize: 11.5, fontWeight: w, height: 1.3, color: color ?? muted);

  static TextStyle eyebrow() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1,
        color: pink,
      );

  static TextStyle tinyTag({
    Color color = Colors.white,
    double size = 9.5,
    double spacing = 0.8,
    FontWeight w = FontWeight.w700,
  }) =>
      GoogleFonts.poppins(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          height: 1,
          color: color);

  static const rPill = 999.0;
  static const rCard = 20.0;
  static const rInspiration = 18.0;

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B1410), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(
        color: Color(0x590B1410),
        blurRadius: 32,
        spreadRadius: -22,
        offset: Offset(0, 18)),
  ];
  static const banner = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B1410), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(
        color: Color(0x660B1410),
        blurRadius: 28,
        spreadRadius: -22,
        offset: Offset(0, 14)),
  ];
  static const mini = <BoxShadow>[
    BoxShadow(
        color: Color(0x730B1410),
        blurRadius: 24,
        spreadRadius: -16,
        offset: Offset(0, 12)),
  ];
}

/// Item générique affiché dans le carrousel d'une rubrique.
class RubriqueItem {
  final String title;
  final String subtitle;
  final String photoUrl;
  final bool isVerified;
  final void Function(BuildContext context) onTap;

  /// Commerce sous-jacent. Si fourni, le tap ouvre un pager swipable sur tous
  /// les items commerce de la liste ; sinon, [onTap] est utilisé.
  final CommerceModel? commerce;

  const RubriqueItem({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.onTap,
    this.isVerified = false,
    this.commerce,
  });
}

class RubriqueChip {
  final String label;
  final IconData icon;
  final String key; // clé passée à itemsBuilder
  const RubriqueChip(this.label, this.icon, this.key);
}

class RubriqueConfig {
  final RubriqueTheme theme;
  final String eyebrowLeft;
  final String eyebrowRight;
  final String title;
  final String subtitle;
  final String sectionTitle;
  final List<RubriqueChip> chips;

  /// Clé rubrique persistée en base (food | family | sport | culture | night).
  /// Sert à interroger `inspirationsProvider` pour le carrousel dynamique.
  final String rubriqueKey;

  final String bannerTitle;
  final String bannerSubtitle;
  final String bannerCta;

  /// Renvoie l'AsyncValue de la liste d'items pour la chip sélectionnée.
  final AsyncValue<List<RubriqueItem>> Function(
      WidgetRef ref, String chipKey) itemsBuilder;

  final VoidCallback onBack;
  final VoidCallback? onBannerCta;

  /// Sections additionnelles propres à la rubrique, insérées juste avant le
  /// carrousel "Inspirations". Permet à une feature (ex. Sport : matchs à
  /// domicile) d'injecter un bloc maison sans coupler ce widget générique
  /// `core` aux features.
  final List<Widget> Function(BuildContext context)? extraSections;

  const RubriqueConfig({
    required this.theme,
    required this.eyebrowLeft,
    required this.eyebrowRight,
    required this.title,
    required this.subtitle,
    required this.sectionTitle,
    required this.chips,
    required this.rubriqueKey,
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.bannerCta,
    required this.itemsBuilder,
    required this.onBack,
    this.onBannerCta,
    this.extraSections,
  });
}

/// Vue landing générique d'une rubrique (design Food, couleur signature).
class RubriqueLandingView extends ConsumerStatefulWidget {
  final RubriqueConfig config;
  const RubriqueLandingView({super.key, required this.config});

  @override
  ConsumerState<RubriqueLandingView> createState() =>
      _RubriqueLandingViewState();
}

class _RubriqueLandingViewState extends ConsumerState<RubriqueLandingView> {
  late String _activeChip = widget.config.chips.first.key;

  VideoPlayerController? _video;
  String? _videoUrl;
  bool _videoError = false;

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

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Ouvre l'item tapé : un pager swipable sur tous les commerces de la liste
  /// si l'item porte un CommerceModel, sinon le handler [onTap] de l'item.
  void _openItem(BuildContext ctx, List<RubriqueItem> items, int index) {
    final tapped = items[index];
    if (tapped.commerce == null) {
      tapped.onTap(ctx);
      return;
    }
    final commerces = <CommerceModel>[];
    var pagerIndex = 0;
    for (var j = 0; j < items.length; j++) {
      final c = items[j].commerce;
      if (c == null) continue;
      if (j == index) pagerIndex = commerces.length;
      commerces.add(c);
    }
    CommercePagerView.open(ctx,
        commerces: commerces, initialIndex: pagerIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final t = cfg.theme;
    final itemsAsync = cfg.itemsBuilder(ref, _activeChip);

    return Container(
      color: RubriqueTheme.bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(cfg),
            const SizedBox(height: 18),
            _chipsRow(cfg),
            _sectionHeader(cfg.sectionTitle, t),
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text('Aucune adresse pour cette sélection.',
                        style: RubriqueTheme.body()),
                  );
                }
                return SizedBox(
                  height: 212,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _ItemCard(
                      item: items[i],
                      theme: t,
                      coupDeCoeur: i == 0,
                      onOpen: (ctx) => _openItem(ctx, items, i),
                    ),
                  ),
                );
              },
              loading: () => SizedBox(
                height: 212,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                    ),
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text('Contenu indisponible.',
                    style: RubriqueTheme.body()),
              ),
            ),
            ...(cfg.extraSections?.call(context) ?? const <Widget>[]),
            ..._inspirationsSection(cfg, t),
            _banner(cfg),
          ],
        ),
      ),
    );
  }

  Widget _chipsRow(RubriqueConfig cfg) {
    final t = cfg.theme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        itemCount: cfg.chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = cfg.chips[i];
          final active = c.key == _activeChip;
          return GestureDetector(
            onTap: () => setState(() => _activeChip = c.key),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                  horizontal: active ? 9 : 8, vertical: active ? 5 : 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? t.accent : RubriqueTheme.surface,
                borderRadius: BorderRadius.circular(RubriqueTheme.rPill),
                border: active
                    ? null
                    : Border.all(color: RubriqueTheme.stroke, width: 1),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: -6,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon,
                      size: 11,
                      color: active ? Colors.white : RubriqueTheme.ink),
                  const SizedBox(width: 5),
                  Text(c.label,
                      style: RubriqueTheme.chip(
                          color:
                              active ? Colors.white : RubriqueTheme.ink)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, RubriqueTheme t, {double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: RubriqueTheme.sectionHeader(
              fontSize: fontSize ?? 14,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voir tout', style: RubriqueTheme.chip(color: t.accent)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 15, color: t.accent),
            ],
          ),
        ],
      ),
    );
  }

  /// Section "Inspirations du moment" — alimentée par la table `inspirations`
  /// filtrée sur `cfg.rubriqueKey` et la ville sélectionnée. Section
  /// entièrement masquée (titre inclus) quand il n'y a aucune carte.
  List<Widget> _inspirationsSection(RubriqueConfig cfg, RubriqueTheme t) {
    final items =
        ref.watch(inspirationsProvider(cfg.rubriqueKey)).valueOrNull ??
            const <Inspiration>[];
    if (items.isEmpty) return const [];
    return [
      _sectionHeader('Inspirations du moment', t, fontSize: 11.5),
      SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _RubriqueInspirationCard(
            data: items[i],
            theme: t,
            onTap: () => _onInspirationTap(cfg, items[i]),
            onOpenSite: () => _openLink(items[i].siteUrl),
          ),
        ),
      ),
    ];
  }

  /// Tap carte : bascule sur le chip dont la clé matche `insp.theme`
  /// (insensible à la casse) si la rubrique en a un, sinon ouvre le site.
  void _onInspirationTap(RubriqueConfig cfg, Inspiration insp) {
    final theme = insp.theme.trim();
    if (theme.isNotEmpty) {
      final match = cfg.chips.where(
        (c) => c.key.toLowerCase() == theme.toLowerCase(),
      );
      if (match.isNotEmpty) {
        setState(() => _activeChip = match.first.key);
        return;
      }
    }
    if (insp.siteUrl.trim().isNotEmpty) {
      _openLink(insp.siteUrl);
    }
  }

  Widget _banner(RubriqueConfig cfg) {
    final t = cfg.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: RubriqueTheme.surface,
          borderRadius: BorderRadius.circular(RubriqueTheme.rCard),
          border: Border.all(color: RubriqueTheme.hairline, width: 1),
          boxShadow: RubriqueTheme.banner,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 20, color: t.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cfg.bannerTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RubriqueTheme.ink)),
                  const SizedBox(height: 2),
                  Text(cfg.bannerSubtitle,
                      style: RubriqueTheme.meta(
                          color: RubriqueTheme.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: cfg.onBannerCta,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(RubriqueTheme.rPill),
                  boxShadow: [
                    BoxShadow(
                      color: t.accent.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: -6,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(cfg.bannerCta,
                    style: RubriqueTheme.chip(
                        color: Colors.white, w: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(RubriqueConfig cfg) {
    final t = cfg.theme;
    final topPad = MediaQuery.of(context).padding.top;
    final bannerAsync = ref.watch(modeBannerVideoProvider);
    final banner = bannerAsync.asData?.value;
    if (banner != null && _videoUrl != banner.videoUrl) {
      _disposeVideo();
      _initVideo(banner.videoUrl);
    }
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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.accent, t.accent2],
                ),
              ),
            ),
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x00000000)],
                  ),
                ),
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
            right: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: cfg.onBack,
                behavior: HitTestBehavior.opaque,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.96),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.chevron_left,
                          size: 17, color: RubriqueTheme.ink),
                    ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cfg.title,
                              style: RubriqueTheme.heroTitle()),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 230),
                            child: Text(cfg.subtitle,
                                style: RubriqueTheme.body(
                                    color: Colors.white
                                        .withValues(alpha: 0.78))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (banner?.linkUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openLink(banner!.linkUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                RubriqueTheme.rPill),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xC70B1410),
                                  borderRadius: BorderRadius.circular(
                                      RubriqueTheme.rPill),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.14),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('En savoir plus',
                                        style: RubriqueTheme.chip(
                                            color: Colors.white,
                                            w: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    const Icon(
                                        Icons.arrow_outward_rounded,
                                        size: 10,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final RubriqueItem item;
  final RubriqueTheme theme;
  final bool coupDeCoeur;
  final void Function(BuildContext context) onOpen;
  const _ItemCard({
    required this.item,
    required this.theme,
    required this.coupDeCoeur,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        item.photoUrl.isNotEmpty && item.photoUrl.startsWith('http');
    return GestureDetector(
      onTap: () => onOpen(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RubriqueTheme.rCard),
          border: Border.all(color: RubriqueTheme.hairline, width: 1),
          boxShadow: RubriqueTheme.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: item.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFF2A332D)),
                errorWidget: (_, __, ___) => _grad(),
              )
            else
              _grad(),
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
            if (coupDeCoeur)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  decoration: BoxDecoration(
                    color: theme.tealAccent,
                    borderRadius:
                        BorderRadius.circular(RubriqueTheme.rPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 5, color: Color(0xFF08221C)),
                      const SizedBox(width: 2),
                      Text('À LA UNE',
                          style: RubriqueTheme.tinyTag(
                              color: const Color(0xFF08221C),
                              size: 5,
                              spacing: 0.5,
                              w: FontWeight.w800)),
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
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RubriqueTheme.cardName()),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RubriqueTheme.meta(
                            color:
                                Colors.white.withValues(alpha: 0.75))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grad() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A332D), Color(0xFF142019)],
          ),
        ),
      );
}

/// Carte du carrousel "Inspirations" (commune Famille/Sport/Culture/Night).
/// Mêmes dimensions compactes que la carte Food, mais utilise la couleur
/// signature de la rubrique pour le dégradé de fallback et la flèche.
class _RubriqueInspirationCard extends StatelessWidget {
  final Inspiration data;
  final RubriqueTheme theme;
  final VoidCallback onTap;
  final VoidCallback onOpenSite;
  const _RubriqueInspirationCard({
    required this.data,
    required this.theme,
    required this.onTap,
    required this.onOpenSite,
  });

  @override
  Widget build(BuildContext context) {
    final hasSite = data.siteUrl.trim().isNotEmpty;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.accent.withValues(alpha: 0.55),
        RubriqueTheme.dark,
      ],
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 124,
        decoration: BoxDecoration(
          color: RubriqueTheme.dark,
          borderRadius: BorderRadius.circular(RubriqueTheme.rInspiration),
          boxShadow: RubriqueTheme.mini,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 62,
              child: data.photoUrl.trim().isEmpty
                  ? DecoratedBox(decoration: BoxDecoration(gradient: gradient))
                  : CachedNetworkImage(
                      imageUrl: data.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => DecoratedBox(
                          decoration: BoxDecoration(gradient: gradient)),
                      errorWidget: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(gradient: gradient)),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RubriqueTheme.meta(
                          color: Colors.white, w: FontWeight.w600),
                    ),
                    if (data.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: RubriqueTheme.tinyTag(
                          color: Colors.white.withValues(alpha: 0.62),
                          size: 9.5,
                          spacing: 0,
                          w: FontWeight.w400,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: hasSite ? onOpenSite : onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.tealAccent,
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
}
