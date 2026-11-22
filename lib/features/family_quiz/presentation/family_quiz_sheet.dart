import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';
import 'package:pulz_app/features/family_quiz/domain/family_quiz.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/tonight_quiz/presentation/tonight_quiz_sheet.dart';

/// Accent de la rubrique Famille (= tuile home, landing Famille).
const _accent = Color(0xFFF2A20C);

/// Bouton flottant « Trouver mon activité », fixé en bas de la landing
/// Famille (visible sans scroller).
class FamilyQuizButton extends StatelessWidget {
  final String ville;

  const FamilyQuizButton({super.key, required this.ville});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FamilyQuizSheet.show(context, ville: ville),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 7, 14, 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accent, Color(0xFFF7BE4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80F2A20C),
              blurRadius: 18,
              spreadRadius: -4,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧸', style: TextStyle(fontSize: 17)),
            const SizedBox(width: 8),
            Text(
              context.l10n.familyQuizButton,
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

/// Questionnaire puis propositions (events famille de la période + lieux).
class FamilyQuizSheet extends ConsumerStatefulWidget {
  final String ville;

  const FamilyQuizSheet({super.key, required this.ville});

  static Future<void> show(BuildContext context, {required String ville}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyQuizSheet(ville: ville),
    );
  }

  @override
  ConsumerState<FamilyQuizSheet> createState() => _FamilyQuizSheetState();
}

enum _Step { age, wishes, where, when, results }

class _FamilyQuizSheetState extends ConsumerState<FamilyQuizSheet> {
  _Step _step = _Step.age;
  final Set<FamilyAge> _ages = {};
  final Set<FamilyWish> _wishes = {};
  FamilyWhere? _where;
  FamilyWhen? _when;

  List<FamilySection>? _sections;
  int _seed = DateTime.now().millisecondsSinceEpoch % 100000;

  static const _flow = [_Step.age, _Step.wishes, _Step.where, _Step.when];

  bool get _canContinue => switch (_step) {
        _Step.age => _ages.isNotEmpty,
        _Step.wishes => _wishes.isNotEmpty,
        _Step.where => _where != null,
        _Step.when => _when != null,
        _Step.results => false,
      };

  void _next() {
    final i = _flow.indexOf(_step);
    if (i < _flow.length - 1) {
      setState(() => _step = _flow[i + 1]);
    } else {
      _generate();
    }
  }

  void _back() {
    if (_step == _Step.results) {
      setState(() => _step = _Step.age);
      return;
    }
    final i = _flow.indexOf(_step);
    if (i > 0) {
      setState(() => _step = _flow[i - 1]);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _generate() async {
    setState(() {
      _step = _Step.results;
      _sections = null;
    });
    // Une source en erreur donne une liste vide : on propose sans elle.
    final venues = await ref
        .read(familyAllVenuesProvider.future)
        .catchError((_) => <FamilyVenue>[]);
    final scraped = await ref
        .read(familyScrapedEventsProvider.future)
        .catchError((_) => <Event>[]);
    if (!mounted) return;
    final events = [...ref.read(familyUserEventsProvider), ...scraped];
    setState(
      () => _sections = FamilyQuizEngine().build(
        FamilyAnswers(
          ages: {..._ages},
          wishes: {..._wishes},
          where: _where!,
          when: _when!,
        ),
        venues: venues,
        events: events,
        seed: _seed,
      ),
    );
  }

  void _reshuffle() {
    _seed++;
    _generate();
  }

  void _openCalendar() {
    ref.read(modeSubcategoriesProvider.notifier).select('family', 'A venir');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde les sources en vie pendant le questionnaire (préchargement).
    ref.watch(familyAllVenuesProvider);
    ref.watch(familyScrapedEventsProvider);
    final mq = MediaQuery.of(context);
    // Même densité que « Quoi faire ce soir » : texte un peu réduit, borné.
    final scale = mq.textScaler.clamp(maxScaleFactor: 1.15).scale(1);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(scale * 0.92)),
      child: Container(
        height: mq.size.height * 0.92,
        decoration: const BoxDecoration(
          color: FoodTokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FoodTokens.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _header(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _step == _Step.results ? _results() : _question(),
                  ),
                ),
              ),
              if (_step != _Step.results) _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final i = _flow.indexOf(_step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _back,
            icon: Icon(
              _step == _Step.age
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: FoodTokens.ink,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.familyQuizButton,
              style: FoodTokens.sectionHeader(fontSize: 15),
            ),
          ),
          if (i >= 0)
            Text('${i + 1} / ${_flow.length}', style: FoodTokens.meta()),
        ],
      ),
    );
  }

  // ─── Questions ─────────────────────────────────────────────────────────

  static String wishEmoji(FamilyWish w) => switch (w) {
        FamilyWish.move => '🤸',
        FamilyWish.animals => '🦁',
        FamilyWish.discover => '🔭',
        FamilyWish.show => '🎭',
        FamilyWish.water => '🏊',
        FamilyWish.creative => '🎨',
      };

  (String, String) _wishLabels(FamilyWish w) {
    final l = context.l10n;
    return switch (w) {
      FamilyWish.move => (l.fqMove, l.fqMoveSub),
      FamilyWish.animals => (l.fqAnimals, l.fqAnimalsSub),
      FamilyWish.discover => (l.fqDiscover, l.fqDiscoverSub),
      FamilyWish.show => (l.fqShow, l.fqShowSub),
      FamilyWish.water => (l.fqWater, l.fqWaterSub),
      FamilyWish.creative => (l.fqCreative, l.fqCreativeSub),
    };
  }

  Widget _question() {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: switch (_step) {
        _Step.age => [
            _title(l.fqQAge, l.fqQAgeSub),
            for (final (a, emoji, label, sub) in [
              (FamilyAge.baby, '👶', l.fqAgeBaby, l.fqAgeBabySub),
              (FamilyAge.small, '🧒', l.fqAgeSmall, l.fqAgeSmallSub),
              (FamilyAge.kids, '🎒', l.fqAgeKids, l.fqAgeKidsSub),
              (FamilyAge.teens, '🛹', l.fqAgeTeens, l.fqAgeTeensSub),
            ])
              _option(emoji, label, sub, _ages.contains(a), () {
                setState(() {
                  if (!_ages.remove(a)) _ages.add(a);
                });
              }),
          ],
        _Step.wishes => [
            _title(l.fqQWhat, l.fqQAgeSub),
            for (final w in FamilyWish.values)
              _option(
                wishEmoji(w),
                _wishLabels(w).$1,
                _wishLabels(w).$2,
                _wishes.contains(w),
                () => setState(() {
                  if (!_wishes.remove(w)) _wishes.add(w);
                }),
              ),
          ],
        _Step.where => [
            _title(l.fqQWhere, l.fqQWhereSub),
            for (final (w, emoji, label, sub) in [
              (FamilyWhere.indoor, '🏠', l.fqIndoor, l.fqIndoorSub),
              (FamilyWhere.outdoor, '🌳', l.fqOutdoor, l.fqOutdoorSub),
              (FamilyWhere.any, '🤷', l.fqAnywhere, l.fqAnywhereSub),
            ])
              _option(emoji, label, sub, _where == w,
                  () => setState(() => _where = w)),
          ],
        _Step.when => [
            _title(l.fqQWhen, l.fqQWhenSub),
            for (final (w, emoji, label, sub) in [
              (FamilyWhen.today, '⚡', l.fqToday, l.fqTodaySub),
              (FamilyWhen.weekend, '📅', l.fqWeekend, l.fqWeekendSub),
              (FamilyWhen.week, '🗓️', l.fqWeek, l.fqWeekSub),
            ])
              _option(emoji, label, sub, _when == w,
                  () => setState(() => _when = w)),
          ],
        _Step.results => const [],
      },
    );
  }

  Widget _title(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FoodTokens.sectionHeader(fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, style: FoodTokens.body()),
          ],
        ),
      );

  Widget _option(String emoji, String label, String sub, bool selected,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _accent : FoodTokens.surface,
            borderRadius: BorderRadius.circular(FoodTokens.rCard),
            border: Border.all(color: selected ? _accent : FoodTokens.stroke),
            boxShadow: selected ? _accentShadow : null,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: FoodTokens.bannerTitle().copyWith(
                        fontSize: 13.5,
                        color: selected ? Colors.white : FoodTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: FoodTokens.meta(
                        color: selected ? Colors.white : FoodTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? Colors.white : FoodTokens.dim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final isLast = _flow.last == _step;
    final enabled = _canContinue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: GestureDetector(
        onTap: enabled ? _next : null,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? _accent : FoodTokens.stroke,
            borderRadius: BorderRadius.circular(FoodTokens.rPill),
            boxShadow: enabled ? _accentShadow : null,
          ),
          child: Text(
            isLast ? context.l10n.tqSeeIdeas : context.l10n.commonNext,
            style: FoodTokens.bannerTitle().copyWith(
              fontSize: 14,
              color: enabled ? Colors.white : FoodTokens.dim,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Propositions ──────────────────────────────────────────────────────

  Widget _results() {
    final sections = _sections;
    if (sections == null) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        Text(l.fqResultsTitle(widget.ville),
            style: FoodTokens.sectionHeader(fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _pillButton(
                    Icons.shuffle_rounded, l.tripOtherProposal, _reshuffle)),
            const SizedBox(width: 10),
            Expanded(
              child: _pillButton(
                Icons.tune_rounded,
                l.commonEdit,
                () => setState(() => _step = _Step.age),
                outlined: true,
              ),
            ),
          ],
        ),
        for (final s in sections) ..._section(s),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: _openCalendar,
            icon: const Icon(Icons.calendar_month_rounded, color: _accent),
            label: Text(
              l.fqSeeCalendar,
              style: FoodTokens.meta(color: _accent, w: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _section(FamilySection s) {
    final l = context.l10n;
    return [
      const SizedBox(height: 22),
      Text(
        '${wishEmoji(s.wish)}  ${_wishLabels(s.wish).$1}'.toUpperCase(),
        style: FoodTokens.eyebrow().copyWith(color: _accent),
      ),
      const SizedBox(height: 10),
      if (s.isEmpty) Text(l.fqNothing(widget.ville), style: FoodTokens.meta()),
      if (s.events.isNotEmpty) ...[
        _subLabel(l.fqEvents),
        for (final e in s.events) _eventCard(e),
      ],
      if (s.places.isNotEmpty) ...[
        if (s.events.isNotEmpty) _subLabel(l.fqPlaces),
        for (final v in s.places) _placeCard(v),
      ],
    ];
  }

  Widget _subLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 2),
        child: Text(text,
            style: FoodTokens.meta(color: FoodTokens.ink, w: FontWeight.w700)),
      );

  String _dateLabel(Event e) {
    final d = DateTime.tryParse(e.dateDebut);
    if (d == null) return '';
    final f = DateTime.tryParse(e.dateFin);
    String fmt(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    return f != null && f.isAfter(d) ? '${fmt(d)} - ${fmt(f)}' : fmt(d);
  }

  Widget _eventCard(Event e) {
    final time = e.horaires.split(',').first.trim();
    final where = e.lieuNom.isNotEmpty ? e.lieuNom : e.commune;
    return QuizResultCard(
      imageUrl: e.photoPath ?? '',
      emoji: '🎈',
      title: e.titre,
      lines: [
        [_dateLabel(e), if (time.isNotEmpty) time].where((s) => s.isNotEmpty)
            .join(' · '),
        if (where.isNotEmpty) where,
        if (e.isFree) context.l10n.priceFree,
      ],
      onTap: () => EventFullscreenPopup.show(
        context,
        e,
        'assets/images/pochette_enfamille.jpg',
      ),
    );
  }

  Widget _placeCard(FamilyVenue v) {
    final c = FamilyVenueRowCard.toCommerce(v);
    return QuizResultCard(
      imageUrl: v.photo,
      emoji: '📍',
      title: v.name,
      lines: [
        [
          if (v.category.isNotEmpty) anyCategoryLabel(context, v.category),
          if (v.ville.isNotEmpty) v.ville,
          if (v.isPartner) context.l10n.tripPartner,
        ].join(' · '),
      ],
      onTap: () => CommerceRowCard.openDetail(context, c),
    );
  }

  Widget _pillButton(IconData icon, String label, VoidCallback onTap,
      {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: outlined ? FoodTokens.surface : _accent,
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(color: outlined ? FoodTokens.stroke : _accent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: outlined ? _accent : Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: FoodTokens.meta(
                    color: outlined ? _accent : Colors.white,
                    w: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _accentShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x59F2A20C),
    blurRadius: 14,
    spreadRadius: -6,
    offset: Offset(0, 6),
  ),
];
