import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_row_card.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_tile.dart';
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

    final isAvenir = subcategory == 'A venir';

    return Column(
      children: [
        if (!isAvenir) ...[
          SportBackButton(
            title: displayTitle,
            label: backLabel,
            onBack: onBack,
          ),
          const SizedBox(height: 8),
        ],
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
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DateRangeChipBar(),
          ),
          const SizedBox(height: 4),
          for (final day in sortedDays) ...[
            editorialDateHeader(
              editorialDayLabel(day),
              RubricColors.sport,
              count: grouped[day]!.length,
            ),
            for (final match in grouped[day]!)
              _matchToEditorialTile(context, match),
          ],
        ],
      ),
    );
  }

  EditorialEventRowCard _matchToEditorialTile(
    BuildContext context,
    SupabaseMatch match,
  ) {
    final parsed = DateTime.tryParse(match.date);
    final monthAbbr = parsed != null
        ? DateFormat('MMM', 'fr_FR')
            .format(parsed)
            .replaceAll('.', '')
            .toUpperCase()
        : null;
    final dayNum = parsed?.day.toString();
    final weekDay = parsed != null
        ? DateFormat('EEE', 'fr_FR').format(parsed).toLowerCase()
        : null;
    final title = match.equipe2.isNotEmpty
        ? '${match.equipe1}  vs  ${match.equipe2}'
        : match.equipe1;
    final price = match.gratuit.toLowerCase() == 'oui' ? 'Gratuit' : null;
    final imageUrl =
        match.photoUrl.isNotEmpty ? match.photoUrl : 'assets/images/sc_autres_sport.jpg';

    return EditorialEventRowCard(
      dateMonth: monthAbbr,
      dateDay: dayNum,
      weekDay: weekDay,
      time: match.heure.isNotEmpty ? match.heure : null,
      title: title,
      subtitle: match.competition.isNotEmpty ? match.competition : null,
      venue: match.lieu.isNotEmpty ? match.lieu : null,
      price: price,
      imageUrl: imageUrl,
      accent: RubricColors.sport,
      onTap: () => _openMatchDetail(context, match),
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

}
