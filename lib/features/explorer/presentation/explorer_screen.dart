import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_city_header.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/home/presentation/widgets/banner_carousel.dart';
import 'package:pulz_app/features/search/data/unified_search_service.dart';
import 'package:pulz_app/features/search/domain/search_result.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';

/// Ecran "Explorer" — handoff coherence v1.0.
///
/// Layout :
///  1. CityHeader (logo + Ta ville + ville + avatar)
///  2. Header "Toutes les *offres*" + bouton cadeau (BannerCarouselDialog)
///  3. Barre de recherche locale
///  4. Si query >= 2 chars : liste de resultats (events + matchs + venues)
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final _controller = TextEditingController();
  final _service = UnifiedSearchService();
  Timer? _debounce;
  List<SearchResult>? _results; // null = pas encore cherche, [] = aucun resultat
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final query = raw.trim();
    if (query.length < 2) {
      _debounce?.cancel();
      if (_results != null || _loading) {
        setState(() {
          _results = null;
          _loading = false;
        });
      }
      return;
    }
    setState(() => _loading = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(query));
  }

  Future<void> _doSearch(String query) async {
    _lastQuery = query;
    try {
      final ville = ref.read(selectedCityProvider);
      final results = await _service.search(query, ville: ville);
      if (!mounted || _lastQuery != query) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _results = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EditorialColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: EditorialCityHeader()),
            // Header "Toutes les offres" + bouton cadeau
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EditorialSpacing.screen,
                  EditorialSpacing.lg,
                  EditorialSpacing.screen,
                  EditorialSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '✦',
                      style: TextStyle(
                        color: EditorialColors.magenta,
                        fontSize: 18,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: EditorialSpacing.md),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Toutes les ',
                              style: EditorialText.displayTitle()
                                  .copyWith(fontSize: 24),
                            ),
                            TextSpan(
                              text: 'offres',
                              style: EditorialText.sectionItalic(
                                color: EditorialColors.gold,
                              ).copyWith(fontSize: 24),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GiftButton(
                      onTap: () => BannerCarouselDialog.show(context),
                    ),
                  ],
                ),
              ),
            ),
            // Barre de recherche (TextField actif, debounce 400ms)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EditorialSpacing.screen,
                  0,
                  EditorialSpacing.screen,
                  EditorialSpacing.md,
                ),
                child: _SearchField(
                  controller: _controller,
                  onChanged: _onChanged,
                  onClear: _clear,
                ),
              ),
            ),
            // Resultats / etats vides
            ..._buildResultsSlivers(),
            const SliverToBoxAdapter(
              child: SizedBox(height: EditorialSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultsSlivers() {
    // Aucun query saisi : rien sous la search bar
    if (_results == null && !_loading) return const [];

    if (_loading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.magenta),
            ),
          ),
        ),
      ];
    }

    if (_results!.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Aucun resultat',
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final r = _results![i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: switch (r) {
                  EventResult(:final event) => EventRowCard(event: event),
                  MatchResult(:final match) => MatchRowCard(match: match),
                  VenueResult() => _VenueRow(venue: r),
                },
              );
            },
            childCount: _results!.length,
          ),
        ),
      ),
    ];
  }
}

/// TextField de recherche avec icone + clear button (style FeedScreen).
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.geist(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: 'Rechercher un evenement, un lieu...',
        hintStyle: GoogleFonts.geist(
          fontSize: 13,
          color: AppColors.textFaint,
        ),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.magenta, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textFaint, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide:
              const BorderSide(color: AppColors.magenta, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        isDense: true,
      ),
    );
  }
}

/// Carte resultat venue (basique : photo + nom + categorie + adresse).
class _VenueRow extends StatelessWidget {
  final VenueResult venue;
  const _VenueRow({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: venue.photo != null && venue.photo!.isNotEmpty
                  ? Image.network(
                      venue.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.place,
                          color: AppColors.textFaint,
                          size: 22,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.place,
                        color: AppColors.textFaint,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (venue.categorie.isNotEmpty)
                  Text(
                    venue.categorie,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geistMono(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.magenta,
                    ),
                  ),
                if (venue.adresse.isNotEmpty)
                  Text(
                    venue.adresse,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      color: AppColors.textDim,
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

/// Bouton cadeau circulaire avec gradient magenta→gold + glow.
/// Ouvre le carrousel des offres au tap.
class _GiftButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GiftButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [EditorialColors.magenta, EditorialColors.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: EditorialColors.magenta.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.card_giftcard,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }
}
