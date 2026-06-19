import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/search/data/unified_search_service.dart';
import 'package:pulz_app/features/search/domain/search_result.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchEventsBottomSheet extends ConsumerStatefulWidget {
  const SearchEventsBottomSheet({super.key});

  @override
  ConsumerState<SearchEventsBottomSheet> createState() =>
      _SearchEventsBottomSheetState();
}

class _SearchEventsBottomSheetState
    extends ConsumerState<SearchEventsBottomSheet> {
  final _controller = TextEditingController();
  final _service = UnifiedSearchService();
  Timer? _debounce;
  List<SearchResult>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final ville = ref.read(selectedCityProvider);
      final results = await _service.search(query, ville: ville);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = 'Erreur de recherche';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rechercher un evenement',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A1259),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A0F2E),
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.magenta,
              decoration: InputDecoration(
                hintText: 'Nom, lieu, artiste...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textFaint,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textFaint,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textFaint, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceHi,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(),
          ),
          SizedBox(height: bottomInset > 0 ? 0 : 16),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            _error!,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    if (_results == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: AppColors.lineStrong),
              const SizedBox(height: 8),
              Text(
                'Tape au moins 2 lettres',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'Aucun evenement trouve',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: switch (result) {
            EventResult(:final event) => EventRowCard(event: event),
            MatchResult(:final match) => MatchRowCard(match: match),
            VenueResult() => _VenueSearchTile(venue: result),
          },
        );
      },
    );
  }
}

class _VenueSearchTile extends StatelessWidget {
  final VenueResult venue;
  const _VenueSearchTile({required this.venue});

  bool get _hasPhoto => (venue.photo ?? '').startsWith('http');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // Pochette
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: venue.photo!,
                        fit: BoxFit.cover,
                        memCacheWidth: 96,
                        errorWidget: (_, __, ___) => _thumbFallback(),
                      )
                    : _thumbFallback(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (venue.categorie.isNotEmpty)
                    Text(
                      venue.categorie,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (venue.adresse.isNotEmpty)
                    Text(
                      venue.adresse,
                      style: GoogleFonts.inter(fontSize: 9, color: AppColors.textFaint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Bouton Maps
            IconButton(
              icon: Icon(Icons.map_outlined, size: 22, color: AppColors.textDim),
              tooltip: 'Ouvrir sur la carte',
              visualDensity: VisualDensity.compact,
              onPressed: _openMaps,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => ColoredBox(
        color: const Color(0xFFF1F1F4),
        child: Icon(Icons.storefront, size: 22, color: AppColors.textFaint),
      );

  /// Ouvre la fiche detail in-app (meme sheet que les commerces Night/Food).
  void _openDetail(BuildContext context) {
    final idInt = int.tryParse(venue.id);
    final commerce = CommerceModel(
      nom: venue.name,
      adresse: venue.adresse,
      ville: venue.ville,
      categorie: venue.categorie,
      horaires: venue.horaires,
      telephone: venue.telephone,
      photo: venue.photo ?? '',
      siteWeb: venue.siteWeb ?? '',
      lienMaps: venue.lienMaps ?? '',
      latitude: venue.latitude,
      longitude: venue.longitude,
      // Active les avis in-app si le lieu a un id stable.
      sourceId: idInt,
      sourceTable: idInt != null ? venue.sourceTable : null,
    );
    CommerceRowCard.showDetailSheet(context, commerce);
  }

  void _openMaps() {
    final link = (venue.lienMaps != null && venue.lienMaps!.isNotEmpty)
        ? venue.lienMaps!
        : 'https://www.google.com/maps/search/?api=1&query='
            '${Uri.encodeComponent('${venue.name} ${venue.ville}'.trim())}';
    final uri = Uri.tryParse(link);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
