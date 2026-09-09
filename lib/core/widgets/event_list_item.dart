import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Univers d'un évènement, pour la couleur de l'étiquette catégorie.
/// Voir FEED_LISTE.md §2.
enum EventListCategory { food, night, culture, sport, family, evasion }

extension EventListCategoryX on EventListCategory {
  Color get tagColor {
    switch (this) {
      case EventListCategory.food:
        return AppColors.feedTagFood;
      case EventListCategory.night:
        return AppColors.feedTagNight;
      case EventListCategory.culture:
        return AppColors.feedTagCulture;
      case EventListCategory.sport:
        return AppColors.feedTagSport;
      case EventListCategory.family:
        return AppColors.feedTagFamily;
      case EventListCategory.evasion:
        return AppColors.feedTagEvasion;
    }
  }
}

/// Entrée de liste plein format, style petites annonces (FEED_LISTE.md) :
/// image en haut, texte posé directement sur le fond blanc, aucune Card.
/// Ordre de lecture imposé : prix, caractéristiques, étiquette + distance,
/// lieu, horodatage + pastille.
class EventListItem extends StatelessWidget {
  const EventListItem({
    super.key,
    required this.imageUrl,
    this.galleryCount = 1,
    required this.categoryLabel,
    required this.category,
    required this.price,
    this.priceNote,
    this.isFree = false,
    required this.name,
    required this.time,
    this.duration,
    this.distanceMeters,
    this.venue,
    required this.city,
    this.postalCode,
    required this.timestamp,
    this.isLive = false,
    this.friendCount = 0,
    this.isPro = false,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final String imageUrl;
  final int galleryCount;
  final String categoryLabel;
  final EventListCategory category;
  final String price;
  final String? priceNote;
  final bool isFree;
  final String name;
  final String time;
  final String? duration;
  final double? distanceMeters;
  final String? venue;
  final String city;
  final String? postalCode;
  final String timestamp;
  final bool isLive;
  final int friendCount;
  final bool isPro;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  static final _priceStyle = GoogleFonts.outfit(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.03 * 21,
    color: AppColors.feedText,
  );
  static final _priceStyleFree =
      _priceStyle.copyWith(color: AppColors.feedPriceFree);
  static final _priceNoteStyle = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.feedTextSecondary,
  );
  static final _characteristicsStyle = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.015 * 15,
    height: 1.25,
    color: AppColors.feedText,
  );
  static final _distanceStyle = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.feedTextSecondary,
  );
  static final _venueStyle = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.feedText,
  );
  static final _timestampStyle = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.feedTextSecondary,
  );
  static final _pillStyle = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// « 850 m » sous 1 km, « 1,4 km » au-dela. Voir FEED_LISTE.md §7.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String get _venueLine {
    final v = venue;
    final cityPart = postalCode != null && postalCode!.isNotEmpty
        ? '$city $postalCode'
        : city;
    if (v == null || v.isEmpty) return cityPart;
    return '$v · $cityPart';
  }

  String get _characteristicsLine {
    final parts = [
      name,
      time,
      if (duration != null && duration!.isNotEmpty) duration!,
    ];
    return parts.join(' · ');
  }

  String get _semanticsLabel {
    final parts = <String>[
      price,
      name,
      time,
      _venueLine,
      if (distanceMeters != null) formatDistance(distanceMeters!),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _semanticsLabel,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: const Color(0x0A15121C),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventGallery(
                imageUrl: imageUrl,
                galleryCount: galleryCount,
                categoryLabel: categoryLabel,
                isLive: isLive,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price, style: isFree ? _priceStyleFree : _priceStyle),
                  if (priceNote != null && priceNote!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(priceNote!, style: _priceNoteStyle),
                  ],
                ],
              ),
              const SizedBox(height: 9),
              Text(
                _characteristicsLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _characteristicsStyle,
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  _CategoryTag(label: categoryLabel, color: category.tagColor),
                  if (distanceMeters != null) ...[
                    const SizedBox(width: 13),
                    Text('·', style: _distanceStyle),
                    const SizedBox(width: 13),
                    Text(
                      formatDistance(distanceMeters!),
                      style: _distanceStyle,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 15,
                    color: AppColors.feedText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _venueLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _venueStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timestamp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _timestampStyle,
                    ),
                  ),
                  if (friendCount > 0)
                    _Pill(
                      label:
                          '$friendCount ${friendCount == 1 ? "ami" : "amis"}',
                      color: AppColors.feedFriendsBadge,
                      style: _pillStyle,
                    )
                  else if (isPro)
                    _Pill(
                      label: 'Pro',
                      color: AppColors.feedProBadge,
                      style: _pillStyle,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.style});

  final String label;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label, style: style.copyWith(color: color)),
    );
  }
}

/// Rectangle a pointe triangulaire (FEED_LISTE.md §5). La pointe fait partie
/// de la boite de l'etiquette (CustomPainter dessine la forme complete),
/// donc rien ne peut deborder sur l'element suivant.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.color});

  final String label;
  final Color color;

  static final _style = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * 12,
    color: AppColors.feedText,
  );

  static const _leftPad = 13.0;
  static const _rightPad = 15.0;
  static const _pointWidth = 13.0;
  static const _height = 34.0;

  @override
  Widget build(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: label.toUpperCase(), style: _style),
      textDirection: TextDirection.ltr,
    )..layout();
    final totalWidth = _leftPad + tp.width + _rightPad + _pointWidth;

    return SizedBox(
      width: totalWidth,
      height: _height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(totalWidth, _height),
            painter: _CategoryTagPainter(color: color),
          ),
          Positioned(
            left: _leftPad,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label.toUpperCase(), style: _style),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTagPainter extends CustomPainter {
  const _CategoryTagPainter({required this.color});

  final Color color;
  static const _radius = 4.0;
  static const _pointWidth = 13.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rectRight = size.width - _pointWidth;
    final path = Path()
      ..moveTo(_radius, 0)
      ..lineTo(rectRight, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(rectRight, size.height)
      ..lineTo(_radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - _radius)
      ..lineTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CategoryTagPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Image (ratio 16/11.6, rayon 14) + libellé catégorie, favori, indicateurs
/// de galerie et badge LIVE clignotant (FEED_LISTE.md §6).
class _EventGallery extends StatefulWidget {
  const _EventGallery({
    required this.imageUrl,
    required this.galleryCount,
    required this.categoryLabel,
    required this.isLive,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final String imageUrl;
  final int galleryCount;
  final String categoryLabel;
  final bool isLive;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  State<_EventGallery> createState() => _EventGalleryState();
}

class _EventGalleryState extends State<_EventGallery> {
  int _page = 0;
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 11.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // BoxFit.contain (pas cover) : une affiche d'event est le plus
            // souvent en portrait, "cover" dans ce cadre large la tronquait
            // fortement en haut/bas. Le fond neutre derriere comble les
            // bandes laissees vides par le contain plutot que du blanc cru.
            const ColoredBox(color: Color(0xFFF1EEE9)),
            widget.galleryCount > 1
                ? PageView.builder(
                    controller: _controller,
                    itemCount: widget.galleryCount,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (_, __) => CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                  ),
            Positioned(
              top: 12,
              left: 14,
              child: Text(
                widget.categoryLabel.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.20 * 10,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Color(0x80000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _FavoriteButton(
                isFavorite: widget.isFavorite,
                onTap: widget.onFavoriteTap,
              ),
            ),
            if (widget.galleryCount > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.galleryCount, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 34 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            if (widget.isLive)
              const Positioned(
                left: 8,
                bottom: 8,
                child: _LiveBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _controller,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? AppColors.magenta : AppColors.feedText,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.feedLiveBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.4).animate(_controller),
            child: const _Dot(),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06 * 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }
}

/// Titre de section suivi des entrées séparées par des filets pleine
/// largeur moins les marges (FEED_LISTE.md §4).
class EventListSection extends StatelessWidget {
  const EventListSection({super.key, required this.title, required this.items});

  final String title;
  final List<EventListItem> items;

  static final _titleStyle = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * 17,
    color: AppColors.feedText,
  );

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(title, style: _titleStyle),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.feedDivider,
          indent: 20,
          endIndent: 20,
        ),
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1)
            const Divider(
              height: 8,
              thickness: 2,
              color: AppColors.feedDivider,
              indent: 20,
              endIndent: 20,
            ),
        ],
      ],
    );
  }
}
