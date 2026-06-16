import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart'
    show RubriqueTheme;
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/sport/state/home_matches_by_sport_provider.dart';

/// Bloc "Matchs à domicile" de la page Sport : les prochains matchs à domicile
/// regroupés par discipline (Rugby, Foot, Basket, Hand). Réutilise le style de
/// section (RubriqueTheme) et la carte `MatchRowCard` pour rester cohérent avec
/// le reste de la page. Entièrement masqué s'il n'y a aucun match à venir.
class SportHomeMatchesSection extends ConsumerWidget {
  const SportHomeMatchesSection({super.key});

  /// Accent violet de la rubrique Sport.
  static const _accent = Color(0xFFA020F0);

  /// Nombre de matchs affichés par discipline dans le bloc.
  static const _maxPerSport = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bySport = ref.watch(homeMatchesBySportProvider).valueOrNull ??
        const <String, List<SupabaseMatch>>{};

    final groups = [
      for (final s in kHomeMatchSports)
        if ((bySport[s.key] ?? const <SupabaseMatch>[]).isNotEmpty)
          (sport: s, matches: bySport[s.key]!),
    ];
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            'Matchs à domicile',
            style: RubriqueTheme.sectionHeader(fontSize: 14),
          ),
        ),
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            child: Text(
              '${g.sport.emoji}  ${g.sport.label}',
              style: RubriqueTheme.chip(color: _accent),
            ),
          ),
          for (final m in g.matches.take(_maxPerSport))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: MatchRowCard(match: m),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
