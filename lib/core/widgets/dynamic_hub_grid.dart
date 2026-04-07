import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/core/state/categories_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Callback pour obtenir le count d'une catégorie (optionnel).
typedef CategoryCountProvider = FutureProvider<int> Function(String searchTag);

/// Hub grid dynamique qui construit ses sections depuis la table `categories`.
/// Remplace les 7 hub grids hardcodés (night, gaming, family, culture, food, tourisme, sport).
class DynamicHubGrid extends ConsumerWidget {
  final String mode;
  final CategoryCountProvider? countProvider;
  final String? avenirSubtitle;
  final double cardWidth;

  const DynamicHubGrid({
    super.key,
    required this.mode,
    this.countProvider,
    this.avenirSubtitle,
    this.cardWidth = 130,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final groupsAsync = ref.watch(modeCategoryGroupsProvider(mode));

    return groupsAsync.when(
      data: (groups) {
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
        );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            for (final group in groups) ...[
              // Groupe "A venir" → banner spécial
              if (_isAvenirGroup(group))
                _AvenirBanner(
                  gradient: gradient,
                  mode: mode,
                  subtitle: avenirSubtitle,
                  countProvider: countProvider,
                )
              // Groupe avec 1 item → carte pleine largeur
              else if (group.categories.length == 1)
                _buildFullWidthSection(group, gradient, ref)
              // Groupe avec 2 items → grid 2 colonnes
              else if (group.categories.length == 2)
                _buildGridSection(group, gradient, ref)
              // Groupe avec 3+ items → scroll horizontal
              else
                _buildHorizontalSection(group, gradient, ref),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }

  bool _isAvenirGroup(AppCategoryGroup group) {
    return group.categories.length == 1 &&
        group.categories.first.searchTag == 'A venir';
  }

  Widget _buildFullWidthSection(
    AppCategoryGroup group,
    LinearGradient gradient,
    WidgetRef ref,
  ) {
    final cat = group.categories.first;
    final count = countProvider != null
        ? ref.watch(countProvider!(cat.searchTag)).valueOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: group.name),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: DaySubcategoryCard(
            emoji: '',
            label: cat.label,
            image: cat.imageUrl.isNotEmpty ? cat.imageUrl : null,
            count: count,
            gradient: gradient,
            isScraped: cat.displayType == 'events' || cat.displayType == 'matches',
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select(mode, cat.searchTag),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalSection(
    AppCategoryGroup group,
    LinearGradient gradient,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: group.name),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final cat in group.categories)
                _buildCard(cat, gradient, ref, inHorizontal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(
    AppCategoryGroup group,
    LinearGradient gradient,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: group.name),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            for (final cat in group.categories)
              _buildCard(cat, gradient, ref, inHorizontal: false),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(
    AppCategory cat,
    LinearGradient gradient,
    WidgetRef ref, {
    required bool inHorizontal,
  }) {
    final count = countProvider != null
        ? ref.watch(countProvider!(cat.searchTag)).valueOrNull
        : null;

    final card = DaySubcategoryCard(
      emoji: '',
      label: cat.label,
      image: cat.imageUrl.isNotEmpty ? cat.imageUrl : null,
      count: count,
      gradient: gradient,
      isScraped: cat.displayType == 'events' || cat.displayType == 'matches',
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select(mode, cat.searchTag),
    );

    if (inHorizontal) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SizedBox(width: cardWidth, child: card),
      );
    }
    return card;
  }
}

class _AvenirBanner extends ConsumerWidget {
  final LinearGradient gradient;
  final String mode;
  final String? subtitle;
  final CategoryCountProvider? countProvider;

  const _AvenirBanner({
    required this.gradient,
    required this.mode,
    this.subtitle,
    this.countProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = countProvider != null
        ? ref.watch(countProvider!('A venir')).valueOrNull
        : null;

    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select(mode, 'A venir'),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/pochette_default.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, size: 10, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A venir',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (count != null && count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }
}
