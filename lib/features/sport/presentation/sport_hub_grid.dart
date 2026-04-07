import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/sport/state/city_sport_info_provider.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Hub grid Sport — construit dynamiquement depuis la table categories.
class SportHubGrid extends ConsumerWidget {
  const SportHubGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(sportSummaryProvider);
    final city = ref.watch(selectedCityProvider);

    return Column(
      children: [
        // Resume sport en haut
        if (summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              onTap: () => _showSportInfo(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('\u26BD', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sport a $city',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),
        // Hub grid
        Expanded(
          child: DynamicHubGrid(
            mode: 'sport',
            countProvider: (tag) => sportSubcategoryCountProvider(tag),
          ),
        ),
      ],
    );
  }

  void _showSportInfo(BuildContext context, WidgetRef ref) {
    final infosAsync = ref.read(citySportInfoProvider);
    final city = ref.read(selectedCityProvider);
    final infos = infosAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SportInfoSheet(infos: infos, city: city),
    );
  }
}

class _SportInfoSheet extends StatelessWidget {
  final List<SportInfo> infos;
  final String city;

  const _SportInfoSheet({required this.infos, required this.city});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SportInfo>>{};
    for (final info in infos) {
      grouped.putIfAbsent(info.category, () => []).add(info);
    }

    final categoryEmojis = {
      'equipe': '\u{1F3C6}',
      'actu': '\u{1F4F0}',
      'pratiquer': '\u{1F3CB}\u{FE0F}',
      'event': '\u{1F3DF}\u{FE0F}',
    };
    final categoryLabels = {
      'equipe': 'Equipes de $city',
      'actu': 'Actu sport',
      'pratiquer': 'Ou pratiquer',
      'event': 'Events a venir',
    };
    final order = ['equipe', 'actu', 'event', 'pratiquer'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('\u26BD Sport a $city', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final cat in order)
                  if (grouped.containsKey(cat)) ...[
                    Row(
                      children: [
                        Text(categoryEmojis[cat] ?? '', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(categoryLabels[cat] ?? cat, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final info in grouped[cat]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A3E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(info.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(info.description, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
