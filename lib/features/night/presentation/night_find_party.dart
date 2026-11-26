import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/utils/city_hub_resolver.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_tile.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/night/presentation/night_party_quiz_sheet.dart';

/// « Trouver ma soirée » (rubrique Night, 2026-11-22) : bouton flottant en
/// bas de la landing Night. Depuis le 2026-11-26 il ouvre un questionnaire
/// (NightPartyQuizSheet) qui oriente vers des établissements ; la liste de
/// toutes les soirées et de tous les concerts à venir (events scrapés + events
/// de la communauté), groupés par jour, avec un filtre Tout / Soirées /
/// Concerts, reste accessible en bas des propositions.

enum NightPartyKind { soiree, concert }

final _concertMeta = RegExp(
    r'(?<![a-zà-ÿ])(concerts?|musique|showcase|live)(?![a-zà-ÿ])',
    caseSensitive: false);
final _concertTitle = RegExp(r'(?<![a-zà-ÿ])concert', caseSensitive: false);
final _soiree = RegExp(
  r'(?<![a-zà-ÿ])(soir[ée]es?|club(bing)?|dj|party|disco|techno|house|after|electro|[ée]lectro|bal)(?![a-zà-ÿ])',
  caseSensitive: false,
);
final _notParty = RegExp(
  r'comedy|humour|stand.?up|th[ée][aâ]tre|marionnet|cin[ée]|film|atelier|enfant|famil|conf[ée]rence|visite|op[ée]ra',
  caseSensitive: false,
);

/// Bornes de mots écrites à la main : en Dart, `\b` ignore les lettres
/// accentuées (« soirée » ne serait pas reconnu).
///
/// Classe un event en soirée ou concert, sinon null. Plus strict que les
/// chips du Feed (où « festival » attrape un festival de marionnettes,
/// « club » un comedy club et « disco » « Discover Toulouse ») : les mots
/// sont cherchés en entier, et humour, théâtre, cinéma, ateliers, events
/// famille sont écartés.
NightPartyKind? nightPartyKindOf(Event e) {
  final meta = '${e.categorie} ${e.type}';
  final title = e.titre;
  if (e.rubrique == 'family' || _notParty.hasMatch('$meta $title')) {
    return null;
  }
  if (_concertMeta.hasMatch(meta) || _concertTitle.hasMatch(title)) {
    return NightPartyKind.concert;
  }
  if (e.rubrique == 'night' ||
      _soiree.hasMatch(meta) ||
      _soiree.hasMatch(title)) {
    return NightPartyKind.soiree;
  }
  return null;
}

/// Jour d'affichage d'un event : un event sur plusieurs jours déjà commencé
/// (festival du 15 au 30) est rangé sous « Aujourd'hui », pas à sa date de
/// début passée. La liste commence donc toujours au jour même.
DateTime nightPartyDay(Event e, DateTime today) {
  final d = DateTime.tryParse(e.dateDebut);
  if (d == null) return today;
  final day = DateTime(d.year, d.month, d.day);
  return day.isBefore(today) ? today : day;
}

/// Horizon de la liste : au-delà, le Feed reste la référence.
const _horizonDays = 60;

/// Soirées et concerts à venir de la ville (hub), triés par date.
final nightPartiesProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final limit = today.add(const Duration(days: _horizonDays));
  String pad(int v) => v.toString().padLeft(2, '0');
  final todayStr = '${today.year}-${pad(today.month)}-${pad(today.day)}';

  // Toulouse compte ~1 300 events sur 60 jours, au-delà du plafond de 1 000
  // lignes par requête : deux pages en parallèle (doublons écartés plus bas).
  final service = ScrapedEventsSupabaseService();
  final pages = await Future.wait([
    for (final offset in const [0, 1000])
      service.fetchAllEvents(
        dateGte: todayStr,
        ville: city,
        limit: 1000,
        offset: offset,
        rubriques: const ['day', 'culture', 'night', 'family', 'food'],
      ),
  ]);
  final scraped = [for (final (events, _) in pages) ...events];

  // Events de la communauté de la ville (hub), à venir.
  final community = userEvents.where((ue) {
    final hub = CityHubResolver.resolveHub(ue.ville);
    if (hub.toLowerCase() != city.toLowerCase()) return false;
    final d = DateTime.tryParse(ue.date);
    return d != null && !DateTime(d.year, d.month, d.day).isBefore(today);
  }).map((ue) => ue.toEvent());

  final seen = <String>{};
  final out = <Event>[];
  for (final e in [...scraped, ...community]) {
    if (nightPartyKindOf(e) == null) continue;
    final d = DateTime.tryParse(e.dateDebut);
    if (d == null || DateTime(d.year, d.month, d.day).isAfter(limit)) continue;
    // Event terminé (date de fin passée) : jamais affiché.
    final fin = DateTime.tryParse(e.dateFin);
    if (fin != null && DateTime(fin.year, fin.month, fin.day).isBefore(today)) {
      continue;
    }
    final key = e.identifiant.isNotEmpty
        ? e.identifiant
        : '${e.titre.toLowerCase()}_${e.dateDebut}';
    if (seen.add(key)) out.add(e);
  }
  out.sort((a, b) {
    final c = nightPartyDay(a, today).compareTo(nightPartyDay(b, today));
    return c != 0 ? c : a.horaires.compareTo(b.horaires);
  });
  return out;
});

/// Bouton flottant « Trouver ma soirée » (même gabarit que « Trouver mon
/// activité » en Famille), aux couleurs de l'app.
class NightPartyButton extends StatelessWidget {
  const NightPartyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Questionnaire d'abord ; la liste complète reste en bas des
      // propositions.
      onTap: () => NightPartyQuizSheet.show(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 7, 14, 7),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: AppShadows.neon(AppColors.magenta, blur: 18, y: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕺', style: TextStyle(fontSize: 17)),
            const SizedBox(width: 8),
            Text(
              context.l10n.nightFindParty,
              style: FoodTokens.bannerTitle()
                  .copyWith(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Liste plein écran des soirées et concerts à venir.
class NightPartyPage extends ConsumerStatefulWidget {
  const NightPartyPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NightPartyPage(),
      ),
    );
  }

  @override
  ConsumerState<NightPartyPage> createState() => _NightPartyPageState();
}

class _NightPartyPageState extends ConsumerState<NightPartyPage> {
  /// null = tout.
  NightPartyKind? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(nightPartiesProvider);
    final city = ref.watch(selectedCityProvider);
    const accent = RubricColors.night;

    return Scaffold(
      backgroundColor: EditorialColors.ink,
      appBar: AppBar(
        backgroundColor: EditorialColors.ink,
        foregroundColor: EditorialColors.paper,
        elevation: 0,
        title: Text(l.nightFindParty),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: accent),
        ),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(nightPartiesProvider),
            child: Text(l.landingUnavailable,
                style: const TextStyle(color: accent)),
          ),
        ),
        data: (all) {
          final counts = {
            for (final k in NightPartyKind.values)
              k: all.where((e) => nightPartyKindOf(e) == k).length,
          };
          final events = _filter == null
              ? all
              : all.where((e) => nightPartyKindOf(e) == _filter).toList();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final grouped = <DateTime, List<Event>>{};
          for (final e in events) {
            grouped.putIfAbsent(nightPartyDay(e, today), () => []).add(e);
          }
          final days = grouped.keys.toList()..sort();

          return RefreshIndicator(
            color: accent,
            onRefresh: () => ref.refresh(nightPartiesProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _chips(all.length, counts),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Text(
                      l.nightPartyEmpty(city),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EditorialColors.paper),
                    ),
                  ),
                for (final day in days) ...[
                  editorialDateHeader(
                    editorialDayLabel(context, day),
                    accent,
                    count: grouped[day]!.length,
                  ),
                  for (final e in grouped[day]!)
                    editorialEventTileFromEvent(
                      context,
                      e,
                      accent,
                      fallbackImage: 'assets/images/pochette_concert.webp',
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chips(int total, Map<NightPartyKind, int> counts) {
    final l = context.l10n;
    final options = <(NightPartyKind?, String)>[
      (null, '${l.refineAll} · $total'),
      (
        NightPartyKind.soiree,
        '${l.nightPartySoirees} · ${counts[NightPartyKind.soiree]}'
      ),
      (
        NightPartyKind.concert,
        '${l.nightPartyConcerts} · ${counts[NightPartyKind.concert]}'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (final (kind, label) in options)
            ChoiceChip(
              label: Text(label),
              selected: _filter == kind,
              onSelected: (_) => setState(() => _filter = kind),
              selectedColor: AppColors.magenta,
              backgroundColor: EditorialColors.ink,
              side: BorderSide(
                color: _filter == kind
                    ? AppColors.magenta
                    : EditorialColors.paper.withValues(alpha: 0.3),
              ),
              labelStyle: TextStyle(
                color: _filter == kind ? Colors.white : EditorialColors.paper,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
            ),
        ],
      ),
    );
  }
}
