import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Liste de matchs pour une sous-categorie donnee.
class SportMatchesList extends ConsumerWidget {
  final String subcategory;

  const SportMatchesList({super.key, required this.subcategory});

  static const _matchsChildren = {
    'Rugby', 'Football', 'Basketball', 'Handball',
  };

  static const _eventsChildren = {
    'A venir', 'Boxe', 'Natation', 'Courses a pied', 'Stage de danse', 'Boxe matchs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final matchesAsync = ref.watch(sportMatchesProvider);

    final String backLabel;
    final VoidCallback onBack;

    backLabel = 'Sport';
    onBack = () {
      ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
      ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
    };

    final displayTitle = subcategory == 'Boxe matchs'
        ? 'Gala / Matchs'
        : subcategory == 'Tennis events'
            ? 'Tennis'
            : subcategory == 'Tour de France'
                ? 'Tour de France ${DateTime.now().year}'
                : subcategory == 'JO 2028'
                    ? 'JO 2028'
                    : subcategory;

    return Column(
      children: [
        SportBackButton(
          title: displayTitle,
          label: backLabel,
          onBack: onBack,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun match trouve pour cette categorie',
                  icon: Icons.sports,
                );
              }
              if (subcategory == 'A venir') {
                return _buildGroupedList(matches, modeTheme, ref);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matches.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MatchRowCard(match: matches[index]),
                ),
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => AppErrorWidget(
              message: 'Erreur lors du chargement des matchs',
              onRetry: () => ref.invalidate(sportMatchesProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<SupabaseMatch> matches, dynamic modeTheme, WidgetRef ref) {
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final grouped = <DateTime, List<SupabaseMatch>>{};
    for (final m in matches) {
      final d = DateTime.tryParse(m.date);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (!filter.isInRange(dateOnly)) continue;
      grouped.putIfAbsent(dateOnly, () => []).add(m);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const DateRangeChipBar(),
          const SizedBox(height: 8),
          for (final day in sortedDays) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                day == today
                    ? "Aujourd'hui"
                    : day == tomorrow
                        ? 'Demain'
                        : _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(day)),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            for (final match in grouped[day]!) ...[
              CommunityEventCard(
                title: match.equipe2.isNotEmpty
                    ? '${match.equipe1}  vs  ${match.equipe2}'
                    : match.equipe1,
                subtitle: match.competition.isNotEmpty ? match.competition : null,
                date: match.date,
                time: match.heure.isNotEmpty ? match.heure : null,
                location: match.lieu.isNotEmpty ? match.lieu : null,
                photoUrl: match.photoUrl.isNotEmpty ? match.photoUrl : null,
                fallbackAsset: 'assets/images/sc_autres_sport.jpg',
                tag: match.sport.isNotEmpty ? match.sport : null,
                isFree: match.gratuit.toLowerCase() == 'oui',
                onTap: () => _openMatchDetail(context, match),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  void _openMatchDetail(BuildContext context, SupabaseMatch match) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: match.equipe2.isNotEmpty
            ? '${match.equipe1}  vs  ${match.equipe2}'
            : match.equipe1,
        imageAsset: 'assets/images/sc_autres_sport.jpg',
        imageUrl: match.photoUrl.isNotEmpty ? match.photoUrl : null,
        infos: [
          if (match.sport.isNotEmpty)
            DetailInfoItem(Icons.sports, match.sport),
          if (match.competition.isNotEmpty)
            DetailInfoItem(Icons.emoji_events_outlined, match.competition),
          if (match.date.isNotEmpty)
            DetailInfoItem(Icons.calendar_today, match.date),
          if (match.lieu.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, match.lieu),
        ],
        primaryAction: match.billetterie.isNotEmpty
            ? DetailAction(
                icon: Icons.confirmation_number_outlined,
                label: 'Billetterie',
                url: match.billetterie,
              )
            : null,
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
