import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart';

/// Pills de quartier pour la section « Affinez votre recherche », dérivées des
/// lieux réellement en base (`quartier`, rempli par reverse geocoding) plutôt
/// que d'une liste figée : une ville non traitée n'affiche aucune pill, et la
/// section se masque d'elle-même.
///
/// Les quartiers à un seul lieu sont écartés — un filtre qui ne renvoie qu'une
/// fiche n'aide personne — et le classement va du plus dense au moins dense.
/// Renvoie une liste vide s'il n'y a rien à proposer.
List<RefineChip> quartierChips(List<RubriqueItem> all) {
  final counts = <String, int>{};
  for (final it in all) {
    final q = it.commerce?.quartier.trim() ?? '';
    if (q.isNotEmpty) counts[q] = (counts[q] ?? 0) + 1;
  }
  final kept = counts.entries.where((e) => e.value > 1).toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  if (kept.isEmpty) return const [];
  return [
    RefineChip('Tous', (_) => true),
    for (final e in kept)
      RefineChip(
        e.key,
        (it) => it.commerce?.quartier.trim() == e.key,
        icon: Icons.place_rounded,
      ),
  ];
}
