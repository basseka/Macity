import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/night_plan/data/night_plan_service.dart';
import 'package:pulz_app/features/night_plan/domain/night_stop.dart';

/// « Compose ta soirée » : feuille de route dîner → événement → bar → boîte,
/// construite autour du lieu d'un événement.
class NightPlanSheet extends StatefulWidget {
  final String ville;
  final String eventTitle;
  final String eventCategoryEmoji;
  final double? anchorLat;
  final double? anchorLng;

  const NightPlanSheet({
    super.key,
    required this.ville,
    required this.eventTitle,
    this.eventCategoryEmoji = '🎵',
    this.anchorLat,
    this.anchorLng,
  });

  static Future<void> show(
    BuildContext context, {
    required String ville,
    required String eventTitle,
    String eventCategoryEmoji = '🎵',
    double? anchorLat,
    double? anchorLng,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NightPlanSheet(
        ville: ville,
        eventTitle: eventTitle,
        eventCategoryEmoji: eventCategoryEmoji,
        anchorLat: anchorLat,
        anchorLng: anchorLng,
      ),
    );
  }

  @override
  State<NightPlanSheet> createState() => _NightPlanSheetState();
}

class _NightPlanSheetState extends State<NightPlanSheet> {
  late Future<NightPlan> _future;
  bool _showClub = false;

  static const _magenta = Color(0xFFE91E8C);
  static const _purple = Color(0xFF7B2D8E);

  @override
  void initState() {
    super.initState();
    _future = NightPlanService().build(
      ville: widget.ville,
      anchorLat: widget.anchorLat,
      anchorLng: widget.anchorLng,
    );
  }

  Future<void> _openMaps(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _header(),
          const Divider(height: 1),
          Flexible(
            child: FutureBuilder<NightPlan>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: _magenta),
                    ),
                  );
                }
                final plan = snap.data;
                if (plan == null || plan.isEmpty) return _empty();
                return _timeline(plan);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, _magenta]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.nightlife_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compose ta soirée',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Dîner · concert · bar · boîte',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(NightPlan plan) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        if (plan.dinner != null)
          _stopTile(plan.dinner!, '🍽️', 'Dîner', 'Avant le show', first: true),
        _anchorTile(),
        if (plan.bar != null)
          _stopTile(plan.bar!, '🍸', 'Un verre', 'Pour prolonger la soirée'),
        if (plan.club != null) ...[
          if (!_showClub)
            _goFurther()
          else
            _stopTile(
              plan.club!,
              '🌙',
              'En boîte',
              'Pour finir la nuit',
              last: true,
            ),
        ],
      ],
    );
  }

  // Étape « ancre » = l'événement liké.
  Widget _anchorTile() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _railIcon(widget.eventCategoryEmoji, filled: true),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _magenta.withValues(alpha: 0.10),
                      _purple.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _magenta.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TON ÉVÉNEMENT',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _magenta,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.eventTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goFurther() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _railIcon('🌙'),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showClub = true),
                icon: const Icon(Icons.add_rounded, size: 18, color: _purple),
                label: Text(
                  'Aller encore plus loin : une boîte de nuit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: _purple.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopTile(
    NightStop stop,
    String emoji,
    String label,
    String subtitle, {
    bool first = false,
    bool last = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _railIcon(emoji, hideTop: first, hideBottom: last),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$label · $subtitle',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textFaint,
                          ),
                        ),
                        const Spacer(),
                        if (stop.isPartner) _partnerBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: _thumb(stop.photo),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stop.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _metaLine(stop),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textFaint,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(stop.lienMaps),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: Text(
                          'Y aller',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _magenta,
                          minimumSize: const Size.fromHeight(38),
                          side: BorderSide(
                            color: _magenta.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _metaLine(NightStop stop) {
    final parts = <String>[];
    if (stop.categorie.isNotEmpty) parts.add(stop.categorie);
    if (stop.distanceMeters != null) {
      parts.add(Haversine.formatDistance(stop.distanceMeters!.toDouble()));
    } else if (stop.adresse.isNotEmpty) {
      parts.add(stop.adresse);
    }
    return parts.join(' · ');
  }

  Widget _partnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0B341).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '⭐ Partenaire',
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFB8860B),
        ),
      ),
    );
  }

  // Rail vertical + pastille emoji reliant les étapes.
  Widget _railIcon(
    String emoji, {
    bool filled = false,
    bool hideTop = false,
    bool hideBottom = false,
  }) {
    return SizedBox(
      width: 34,
      child: Column(
        children: [
          Container(
            width: 2,
            height: 8,
            color: hideTop ? Colors.transparent : AppColors.line,
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: filled ? _magenta : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? _magenta : AppColors.lineStrong,
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: hideBottom ? Colors.transparent : AppColors.line,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String photo) {
    if (photo.isNotEmpty && photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) => _thumbPlaceholder(),
        errorWidget: (_, __, ___) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: _magenta.withValues(alpha: 0.08),
      child: const Icon(Icons.place_rounded, color: _magenta, size: 20),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _magenta.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nightlife_rounded,
              size: 34,
              color: _magenta.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pas encore de suggestions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'On n\'a pas trouvé de lieux à ${widget.ville} pour composer ta soirée. Reviens quand la ville sera plus fournie !',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
