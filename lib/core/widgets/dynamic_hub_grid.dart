import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/core/state/categories_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_kicker.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_subcategory_card.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Callback pour obtenir le count d'une catégorie (optionnel).
typedef CategoryCountProvider = FutureProvider<int> Function(String searchTag);

/// Hub grid dynamique editorial (handoff design 2026-04-25).
/// Construit ses sections depuis la table `categories`.
/// Utilise par 6 ecrans : night, food, sport, culture, family, tourisme.
class DynamicHubGrid extends ConsumerWidget {
  final String mode;
  final CategoryCountProvider? countProvider;
  final String? avenirSubtitle;

  const DynamicHubGrid({
    super.key,
    required this.mode,
    this.countProvider,
    this.avenirSubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = RubricColors.of(mode);
    final groupsAsync = ref.watch(modeCategoryGroupsProvider(mode));

    return groupsAsync.when(
      data: (groups) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final group in groups) ...[
              if (_isAvenirGroup(group))
                _AvenirBanner(
                  accent: accent,
                  mode: mode,
                  subtitle: avenirSubtitle,
                  countProvider: countProvider,
                )
              else
                _buildSection(group, accent, ref),
              const SizedBox(height: 22),
            ],
          ],
        );
      },
      loading: () => Center(child: LoadingIndicator(color: accent)),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }

  bool _isAvenirGroup(AppCategoryGroup group) {
    return group.categories.length == 1 &&
        group.categories.first.searchTag == 'A venir';
  }

  Widget _buildSection(
    AppCategoryGroup group,
    Color accent,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kicker section (ex "À DÉCOUVRIR", "POUR CE SOIR")
        EditorialKicker(group.name, color: accent, size: 10),
        const SizedBox(height: 12),
        // Layout selon le nombre d'items
        if (group.categories.length == 1)
          _buildSingleCard(group.categories.first, accent, ref)
        else
          _buildGridCards(group.categories, accent, ref),
      ],
    );
  }

  Widget _buildSingleCard(AppCategory cat, Color accent, WidgetRef ref) {
    final count = countProvider != null
        ? ref.watch(countProvider!(cat.searchTag)).valueOrNull
        : null;
    return EditorialSubcategoryCard(
      label: cat.label,
      kicker: cat.label,
      imageUrl: cat.imageUrl.isNotEmpty ? cat.imageUrl : null,
      count: count,
      accent: accent,
      imageHeight: 120,
      onTap: () =>
          ref.read(modeSubcategoriesProvider.notifier).select(mode, cat.searchTag),
    );
  }

  Widget _buildGridCards(
    List<AppCategory> cats,
    Color accent,
    WidgetRef ref,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 18,
      crossAxisSpacing: 14,
      childAspectRatio: 0.82,
      children: [
        for (final cat in cats)
          Builder(
            builder: (context) {
              final count = countProvider != null
                  ? ref.watch(countProvider!(cat.searchTag)).valueOrNull
                  : null;
              return EditorialSubcategoryCard(
                label: cat.label,
                kicker: cat.label,
                imageUrl: cat.imageUrl.isNotEmpty ? cat.imageUrl : null,
                count: count,
                accent: accent,
                onTap: () => ref
                    .read(modeSubcategoriesProvider.notifier)
                    .select(mode, cat.searchTag),
              );
            },
          ),
      ],
    );
  }
}

/// Banner "À venir" version editoriale : filet vertical accent +
/// label + count tabular.
class _AvenirBanner extends ConsumerWidget {
  final Color accent;
  final String mode;
  final String? subtitle;
  final CategoryCountProvider? countProvider;

  const _AvenirBanner({
    required this.accent,
    required this.mode,
    this.subtitle,
    this.countProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = countProvider != null
        ? ref.watch(countProvider!('A venir')).valueOrNull
        : null;
    return Material(
      color: EditorialColors.dividerSoft,
      child: InkWell(
        onTap: () =>
            ref.read(modeSubcategoriesProvider.notifier).select(mode, 'A venir'),
        splashColor: accent.withValues(alpha: 0.2),
        highlightColor: accent.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A venir',
                    style: EditorialText.catCardTitle(),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: EditorialText.subtitleItalic(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (count != null && count > 0) ...[
              Text(
                count.toString(),
                style: EditorialText.meta().copyWith(
                  color: EditorialColors.paper,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: EditorialColors.paperMuted,
            ),
          ],
        ),
        ),
      ),
    );
  }
}
