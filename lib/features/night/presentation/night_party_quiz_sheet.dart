import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/city/state/search_area_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/night/domain/night_party_quiz.dart';
import 'package:pulz_app/features/night/presentation/night_find_party.dart';
import 'package:pulz_app/features/tonight_quiz/presentation/tonight_quiz_sheet.dart';

/// « Trouver ma soirée » (2026-11-26) : cinq questions (avec qui, ambiance,
/// musique, quand, jusqu'à quelle heure) puis des propositions par
/// ambiance, d'abord les établissements de nuit, puis les soirées et
/// concerts de la période. Le lien du bas ouvre la liste complète.
class NightPartyQuizSheet extends ConsumerStatefulWidget {
  const NightPartyQuizSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NightPartyQuizSheet(),
    );
  }

  @override
  ConsumerState<NightPartyQuizSheet> createState() =>
      _NightPartyQuizSheetState();
}

enum _Step { group, vibes, music, when, late, results }

class _NightPartyQuizSheetState extends ConsumerState<NightPartyQuizSheet> {
  late final String _ville = ref.read(areaVilleProvider);
  late final String _hub = ref.read(selectedCityProvider);
  late final Future<(List<CommerceModel>, Map<int, List<String>>)> _venues =
      _loadVenues();

  _Step _step = _Step.group;
  NightGroup? _group;
  final Set<NightVibe> _vibes = {};
  final Set<NightMusic> _music = {};
  NightWhen? _when;
  NightLate? _late;

  List<NightPartySection>? _sections;

  /// Toutes les soirées de la période choisie (liste complète du bas).
  List<Event> _allEvents = const [];
  int _seed = DateTime.now().millisecondsSinceEpoch % 100000;

  /// La question musique n'est posée que pour danser, concert ou thème.
  List<_Step> get _flow => [
        _Step.group,
        _Step.vibes,
        if (NightPartyAnswers.asksMusic(_vibes)) _Step.music,
        _Step.when,
        _Step.late,
      ];

  /// Lieux de nuit de la commune (GPS), repris sur le hub s'il n'y en a
  /// aucun ; styles des discothèques du hub. Une source en erreur donne
  /// une liste vide.
  Future<(List<CommerceModel>, Map<int, List<String>>)> _loadVenues() async {
    final service = VenuesSupabaseService();
    Future<List<CommerceModel>> fetch(String v) =>
        service.fetchVenues(mode: 'night', ville: v).catchError((Object e) {
          debugPrint('[NightPartyQuiz] venues KO: $e');
          return <CommerceModel>[];
        });
    var list = await fetch(_ville);
    if (list.isEmpty && _hub.isNotEmpty && _hub != _ville) {
      list = await fetch(_hub);
    }
    final genres = await service
        .fetchClubMusicGenres(ville: _hub.isNotEmpty ? _hub : _ville)
        .catchError((Object _) => <int, List<String>>{});
    return (list, genres);
  }

  bool get _canContinue => switch (_step) {
        _Step.group => _group != null,
        _Step.vibes => _vibes.isNotEmpty,
        _Step.music => true, // aucun choix = peu importe
        _Step.when => _when != null,
        _Step.late => _late != null,
        _Step.results => false,
      };

  void _next() {
    final flow = _flow;
    final i = flow.indexOf(_step);
    if (i < flow.length - 1) {
      setState(() => _step = flow[i + 1]);
    } else {
      _generate();
    }
  }

  void _back() {
    if (_step == _Step.results) {
      setState(() => _step = _Step.group);
      return;
    }
    final flow = _flow;
    final i = flow.indexOf(_step);
    if (i > 0) {
      setState(() => _step = flow[i - 1]);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _generate() async {
    setState(() {
      _step = _Step.results;
      _sections = null;
    });
    final (venues, genres) = await _venues;
    final events = await ref
        .read(nightPartiesProvider.future)
        .catchError((Object _) => <Event>[]);
    if (!mounted) return;
    final answers = NightPartyAnswers(
      group: _group!,
      vibes: {..._vibes},
      music: NightPartyAnswers.asksMusic(_vibes) ? {..._music} : const {},
      when: _when!,
      late: _late!,
    );
    final quiz = NightPartyQuiz(
      venues: venues,
      events: events,
      clubGenres: genres,
    );
    final now = DateTime.now();
    setState(() {
      _sections = quiz.build(answers, today: now, seed: _seed);
      _allEvents = quiz.eventsInPeriod(answers.when, now);
    });
  }

  void _reshuffle() {
    _seed++;
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    // Garde la liste des soirées en vie pendant le questionnaire.
    ref.watch(nightPartiesProvider);
    final mq = MediaQuery.of(context);
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
    final flow = _flow;
    final i = flow.indexOf(_step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _back,
            icon: Icon(
              _step == _Step.group
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: FoodTokens.ink,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.nightFindParty,
              style: FoodTokens.sectionHeader(fontSize: 15),
            ),
          ),
          if (i >= 0)
            Text('${i + 1} / ${flow.length}', style: FoodTokens.meta()),
        ],
      ),
    );
  }

  // ─── Questions ─────────────────────────────────────────────────────────

  static String vibeEmoji(NightVibe v) => switch (v) {
        NightVibe.verre => '🍸',
        NightVibe.bar => '🍻',
        NightVibe.danser => '💃',
        NightVibe.concert => '🎤',
        NightVibe.theme => '🎉',
      };

  (String, String) _vibeLabels(NightVibe v) {
    final l = context.l10n;
    return switch (v) {
      NightVibe.verre => (l.npqVerre, l.npqVerreSub),
      NightVibe.bar => (l.npqBar, l.npqBarSub),
      NightVibe.danser => (l.npqDance, l.npqDanceSub),
      NightVibe.concert => (l.npqConcert, l.npqConcertSub),
      NightVibe.theme => (l.npqTheme, l.npqThemeSub),
    };
  }

  Widget _question() {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: switch (_step) {
        _Step.group => [
            _title(l.npqQWho, l.npqQWhoSub),
            for (final (g, emoji, label, sub) in [
              (NightGroup.solo, '🙋', l.npqSolo, l.npqSoloSub),
              (NightGroup.couple, '💑', l.npqCouple, l.npqCoupleSub),
              (NightGroup.amis, '🥂', l.npqFriends, l.npqFriendsSub),
              (NightGroup.bande, '🎊', l.npqGang, l.npqGangSub),
            ])
              _option(emoji, label, sub, _group == g,
                  () => setState(() => _group = g)),
          ],
        _Step.vibes => [
            _title(l.npqQVibe, l.npqQVibeSub),
            for (final v in NightVibe.values)
              _option(
                vibeEmoji(v),
                _vibeLabels(v).$1,
                _vibeLabels(v).$2,
                _vibes.contains(v),
                () => setState(() {
                  if (!_vibes.remove(v)) _vibes.add(v);
                }),
              ),
          ],
        _Step.music => [
            _title(l.npqQMusic, l.npqQMusicSub),
            for (final (m, emoji, label, sub) in [
              (
                NightMusic.electro,
                '🎧',
                l.tripMusicElectro,
                l.tripMusicElectroSub
              ),
              (
                NightMusic.hiphop,
                '🎤',
                l.tripMusicHiphop,
                l.tripMusicHiphopSub
              ),
              (
                NightMusic.latino,
                '💃',
                l.tripMusicLatino,
                l.tripMusicLatinoSub
              ),
              (
                NightMusic.generaliste,
                '🎶',
                l.tripMusicGeneral,
                l.tripMusicGeneralSub
              ),
              (NightMusic.rock, '🎸', l.tripMusicRock, l.tripMusicRockSub),
            ])
              _option(
                emoji,
                label,
                sub,
                _music.contains(m),
                () => setState(() {
                  if (!_music.remove(m)) _music.add(m);
                }),
              ),
          ],
        _Step.when => [
            _title(l.npqQWhen, l.npqQWhenSub),
            for (final (w, emoji, label, sub) in [
              (NightWhen.tonight, '🌙', l.npqTonight, null),
              (NightWhen.tomorrow, '📅', l.npqTomorrow, null),
              (NightWhen.weekend, '🎉', l.npqWeekend, l.npqWeekendSub),
            ])
              _option(emoji, label, sub, _when == w,
                  () => setState(() => _when = w)),
          ],
        _Step.late => [
            _title(l.npqQLate, l.npqQLateSub),
            for (final (w, emoji, label, sub) in [
              (NightLate.early, '🛌', l.npqEarly, l.npqEarlySub),
              (NightLate.two, '🕑', l.npqTwo, l.npqTwoSub),
              (NightLate.allNight, '🌅', l.npqAllNight, l.npqAllNightSub),
            ])
              _option(emoji, label, sub, _late == w,
                  () => setState(() => _late = w)),
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

  Widget _option(String emoji, String label, String? sub, bool selected,
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
            color: selected ? AppColors.magenta : FoodTokens.surface,
            borderRadius: BorderRadius.circular(FoodTokens.rCard),
            border: Border.all(
                color: selected ? AppColors.magenta : FoodTokens.stroke),
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
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: FoodTokens.meta(
                          color: selected ? Colors.white70 : FoodTokens.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.violet : FoodTokens.dim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final l = context.l10n;
    final isLast = _flow.last == _step;
    final enabled = _canContinue;
    final label = isLast
        ? l.tqSeeIdeas
        : (_step == _Step.music && _music.isEmpty)
            ? l.npqAnyMusic
            : l.commonNext;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: GestureDetector(
        onTap: enabled ? _next : null,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.magenta : FoodTokens.stroke,
            borderRadius: BorderRadius.circular(FoodTokens.rPill),
            boxShadow: enabled ? _accentShadow : null,
          ),
          child: Text(
            label,
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
      return const Center(
          child: CircularProgressIndicator(color: AppColors.magenta));
    }
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        Text(l.npqResults(_ville),
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
                () => setState(() => _step = _Step.group),
                outlined: true,
              ),
            ),
          ],
        ),
        for (final s in sections) ..._section(s),
        ..._allEventsList(),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => NightPartyPage.show(context),
            icon: const Icon(Icons.list_rounded, color: AppColors.magenta),
            label: Text(
              l.npqSeeAll,
              style:
                  FoodTokens.meta(color: AppColors.magenta, w: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  /// Liste compacte de toutes les soirées de la période (heure, nom, lieu),
  /// groupée par jour quand la période en couvre plusieurs.
  List<Widget> _allEventsList() {
    final l = context.l10n;
    final title = switch (_when) {
      NightWhen.tomorrow => l.npqAllTomorrow,
      NightWhen.weekend => l.npqAllWeekend,
      _ => l.npqAllTonight,
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final out = <Widget>[
      const SizedBox(height: 28),
      Text(
        '🌙  ${title.toUpperCase()} · ${_allEvents.length}',
        style: FoodTokens.eyebrow().copyWith(color: AppColors.magenta),
      ),
      const SizedBox(height: 8),
    ];
    if (_allEvents.isEmpty) {
      out.add(Text(l.npqAllNone(_ville), style: FoodTokens.meta()));
      return out;
    }
    DateTime? lastDay;
    for (final e in _allEvents) {
      final day = nightPartyDay(e, today);
      if (_when == NightWhen.weekend && day != lastDay) {
        final label = DateFormat.EEEE(locale).add_d().format(day);
        out.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            style: FoodTokens.meta(color: AppColors.violet, w: FontWeight.w700),
          ),
        ));
      }
      lastDay = day;
      out.add(_eventRow(e));
    }
    return out;
  }

  /// Ligne de la liste complète : pochette de l'affiche, nom, heure et lieu.
  Widget _eventRow(Event e) {
    final time =
        RegExp(r'\d{1,2}h\d{0,2}').firstMatch(e.horaires)?.group(0) ?? '';
    final url = e.photoPath ?? '';
    final fallback = Container(
      color: const Color(0x1FE91E63),
      alignment: Alignment.center,
      child: const Text('🎫', style: TextStyle(fontSize: 18)),
    );
    return InkWell(
      onTap: () => EventFullscreenPopup.show(
        context,
        e,
        'assets/images/pochette_concert.webp',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FoodTokens.hairline)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: url.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        memCacheWidth: 144,
                        errorWidget: (_, __, ___) => fallback,
                        placeholder: (_, __) => fallback,
                      )
                    : fallback,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FoodTokens.bannerTitle().copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (time.isNotEmpty)
                          TextSpan(
                            text: time,
                            style: FoodTokens.meta(
                              color: AppColors.magenta,
                              w: FontWeight.w700,
                            ),
                          ),
                        if (time.isNotEmpty && e.lieuNom.isNotEmpty)
                          const TextSpan(text: ' · '),
                        if (e.lieuNom.isNotEmpty) TextSpan(text: e.lieuNom),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FoodTokens.meta(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: FoodTokens.dim),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(NightPartySection s) {
    final l = context.l10n;
    return [
      const SizedBox(height: 22),
      Text(
        '${vibeEmoji(s.vibe)}  ${_vibeLabels(s.vibe).$1}'.toUpperCase(),
        style: FoodTokens.eyebrow().copyWith(color: AppColors.magenta),
      ),
      const SizedBox(height: 10),
      if (s.isEmpty) Text(l.npqNothing(_ville), style: FoodTokens.meta()),
      // Les établissements d'abord : c'est l'objet du questionnaire.
      if (s.places.isNotEmpty) ...[
        if (s.events.isNotEmpty) _subLabel(l.npqPlaces),
        for (final c in s.places) _placeCard(c),
      ],
      if (s.events.isNotEmpty) ...[
        _subLabel(l.npqEvents),
        for (final e in s.events) _eventCard(e),
      ],
    ];
  }

  Widget _subLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 2),
        child: Text(text,
            style:
                FoodTokens.meta(color: AppColors.violet, w: FontWeight.w700)),
      );

  Widget _eventCard(Event e) {
    final time = e.horaires.split(',').first.trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = nightPartyDay(e, today);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Le jour n'est utile que sur plusieurs jours (week-end).
    final dayLabel =
        _when == NightWhen.weekend ? DateFormat.E(locale).format(day) : '';
    return QuizResultCard(
      imageUrl: e.photoPath ?? '',
      emoji: '🎫',
      title: e.titre,
      lines: [
        [
          if (dayLabel.isNotEmpty) dayLabel,
          if (time.isNotEmpty) time,
          if (e.lieuNom.isNotEmpty) e.lieuNom,
        ].join(' · '),
        if (e.isFree)
          context.l10n.priceFree
        else if (e.tarifNormal.isNotEmpty)
          e.tarifNormal,
      ],
      onTap: () => EventFullscreenPopup.show(
        context,
        e,
        'assets/images/pochette_concert.webp',
      ),
    );
  }

  Widget _placeCard(CommerceModel c) => QuizResultCard(
        imageUrl: c.photo,
        emoji: '📍',
        title: c.nom,
        lines: [
          [
            if (c.categorie.isNotEmpty) anyCategoryLabel(context, c.categorie),
            if (c.isPartner) context.l10n.tripPartner,
          ].join(' · '),
          if (c.horaires.isNotEmpty) c.horaires,
        ],
        onTap: () => CommerceRowCard.openDetail(context, c),
      );

  Widget _pillButton(IconData icon, String label, VoidCallback onTap,
      {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: outlined ? FoodTokens.surface : AppColors.magenta,
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(
              color: outlined ? FoodTokens.stroke : AppColors.magenta),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: outlined ? AppColors.magenta : Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: FoodTokens.meta(
                    color: outlined ? AppColors.magenta : Colors.white,
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

/// Ombre des boutons actifs, aux couleurs de l'app.
const _accentShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x59E91E63),
    blurRadius: 14,
    spreadRadius: -6,
    offset: Offset(0, 6),
  ),
];
