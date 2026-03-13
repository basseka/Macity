import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Grille 3 colonnes d'affiches pour les événements de boxe.
class BoxeEventsGrid extends ConsumerWidget {
  const BoxeEventsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final matchesAsync = ref.watch(sportMatchesProvider);

    return Column(
      children: [
        SportBackButton(
          title: 'Boxe',
          label: 'Sport',
          onBack: () {
            ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
            ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun événement de boxe trouvé',
                  icon: Icons.sports_mma,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                itemCount: matches.length,
                itemBuilder: (context, index) => _BoxeAfficheCard(match: matches[index]),
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => AppErrorWidget(
              message: 'Erreur lors du chargement',
              onRetry: () => ref.invalidate(sportMatchesProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoxeAfficheCard extends StatelessWidget {
  final SupabaseMatch match;

  const _BoxeAfficheCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = match.photoUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Affiche
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: match.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallbackImage(),
                errorWidget: (_, __, ___) => _fallbackImage(),
              )
            else
              _fallbackImage(),

            // Gradient overlay bas
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // Titre + date
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.competition,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (match.date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatDate(match.date),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                        ),
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

  Widget _fallbackImage() {
    return Image.asset(
      'assets/images/pochette_boxe.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }

  void _openDetail(BuildContext context) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: match.competition,
        imageAsset: 'assets/images/pochette_boxe.png',
        imageUrl: match.photoUrl.isNotEmpty ? match.photoUrl : null,
        infos: [
          if (match.sport.isNotEmpty)
            DetailInfoItem(Icons.sports_mma, match.sport),
          if (match.competition.isNotEmpty)
            DetailInfoItem(Icons.emoji_events_outlined, match.competition),
          if (match.date.isNotEmpty)
            DetailInfoItem(
              Icons.calendar_today,
              match.heure.isNotEmpty
                  ? '${_formatDate(match.date)} - ${match.heure}'
                  : _formatDate(match.date),
            ),
          if (match.lieu.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, match.lieu),
          if (match.ville.isNotEmpty)
            DetailInfoItem(Icons.location_city, match.ville),
          if (match.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, match.description),
        ],
        primaryAction: match.billetterie.isNotEmpty
            ? DetailAction(
                icon: Icons.confirmation_number_outlined,
                label: 'Billetterie',
                url: match.billetterie,
              )
            : null,
        shareText: _buildShareText(),
      ),
    );
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln(match.competition);
    if (match.date.isNotEmpty) buffer.writeln('Date: ${_formatDate(match.date)}');
    if (match.lieu.isNotEmpty) buffer.writeln('Lieu: ${match.lieu}');
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return raw;
  }
}
