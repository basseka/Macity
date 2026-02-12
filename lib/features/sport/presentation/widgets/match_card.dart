import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

class MatchCard extends ConsumerWidget {
  final SupabaseMatch match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Competition name
            if (match.competition.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  match.competition,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: modeTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Teams vs row
            Row(
              children: [
                // Team 1
                Expanded(
                  child: Text(
                    match.equipe1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Score or VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: match.score.isNotEmpty
                          ? modeTheme.primaryColor
                          : modeTheme.chipBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.score.isNotEmpty ? match.score : 'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: match.score.isNotEmpty
                            ? Colors.white
                            : modeTheme.primaryDarkColor,
                      ),
                    ),
                  ),
                ),

                // Team 2
                Expanded(
                  child: Text(
                    match.equipe2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Date & Lieu row
            Row(
              children: [
                if (match.date.isNotEmpty) ...[
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.heure.isNotEmpty
                          ? '${match.date} - ${match.heure}'
                          : match.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (match.lieu.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.lieu,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // Billetterie button
            if (match.billetterie.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openBilletterie(),
                  icon: const Icon(Icons.confirmation_number_outlined,
                      size: 18,),
                  label: const Text('Billetterie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modeTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openBilletterie() async {
    final uri = Uri.parse(match.billetterie);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
