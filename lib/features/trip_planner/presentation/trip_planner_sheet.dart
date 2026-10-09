import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/trip_planner/data/trip_planner_service.dart';
import 'package:pulz_app/features/trip_planner/domain/trip_plan.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// « Organiser mon trip » : questionnaire (groupe, nombre, duree, repas,
/// activites) puis feuille de route jour par jour avec les lieux en base.
/// Chaque etape ouvre la fiche du lieu ; « Changer » propose un autre lieu.
class TripPlannerSheet extends StatefulWidget {
  final String ville;

  const TripPlannerSheet({super.key, required this.ville});

  static Future<void> show(BuildContext context, {required String ville}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripPlannerSheet(ville: ville),
    );
  }

  @override
  State<TripPlannerSheet> createState() => _TripPlannerSheetState();
}

enum _Step { group, people, days, meals, activities, night, music, plan }

class _TripPlannerSheetState extends State<TripPlannerSheet> {
  late final Future<TripPools> _poolsFuture =
      TripPlannerService().loadPools(widget.ville);

  _Step _step = _Step.group;
  TripGroup? _group;
  int _people = 4;
  int _days = 2;
  final Set<TripMeal> _meals = {TripMeal.midi, TripMeal.soir};
  bool? _activities;
  TripNight? _night;
  /// Styles coches ; {TripMusic.any} = « Peu importe ».
  final Set<TripMusic> _music = {};

  TripPools? _pools;
  TripPlan? _plan;
  int _seed = DateTime.now().millisecondsSinceEpoch % 100000;

  /// Ordre des questions ; « combien » est inutile pour un couple.
  List<_Step> get _flow => [
        _Step.group,
        if (_group != TripGroup.couple) _Step.people,
        _Step.days,
        _Step.meals,
        _Step.activities,
        // Bar / discotheque : pas propose aux familles.
        if (_group != TripGroup.famille) _Step.night,
        // Style musical : seulement si une discotheque est prevue.
        if (_group != TripGroup.famille && _night == TripNight.barClub)
          _Step.music,
      ];

  TripNight get _nightChoice =>
      _group == TripGroup.famille ? TripNight.none : (_night ?? TripNight.none);

  /// Au moins un repas, une activite ou une sortie.
  bool get _hasSomething =>
      _meals.isNotEmpty || _activities == true || _nightChoice != TripNight.none;

  bool get _canContinue => switch (_step) {
        _Step.group => _group != null,
        _Step.activities =>
          _activities != null && (_flow.last != _Step.activities || _hasSomething),
        _Step.night => _night != null && _hasSomething,
        _Step.music => _music.isNotEmpty,
        _ => true,
      };

  /// Choix multiple ; « Peu importe » est exclusif des styles.
  void _toggleMusic(TripMusic m) {
    if (m == TripMusic.any) {
      final wasAny = _music.contains(TripMusic.any);
      _music.clear();
      if (!wasAny) _music.add(TripMusic.any);
      return;
    }
    _music.remove(TripMusic.any);
    if (!_music.remove(m)) _music.add(m);
  }

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
    if (_step == _Step.plan) {
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

  TripAnswers get _answers => TripAnswers(
        group: _group!,
        people: _group == TripGroup.couple ? 2 : _people,
        days: _days,
        meals: {..._meals},
        activities: _activities ?? false,
        night: _nightChoice,
        music: _nightChoice == TripNight.barClub
            ? _music.where((m) => m != TripMusic.any).toSet()
            : const {},
      );

  Future<void> _generate() async {
    setState(() => _step = _Step.plan);
    _pools ??= await _poolsFuture;
    if (!mounted) return;
    setState(() => _plan = _pools!.build(_answers, seed: _seed));
  }

  void _reshuffle() {
    _seed++;
    setState(() => _plan = _pools!.build(_answers, seed: _seed));
  }

  void _swap(int dayIdx, int stopIdx) {
    final plan = _plan!;
    final stop = plan.days[dayIdx].stops[stopIdx];
    final alt = _pools!.alternativeFor(plan, dayIdx, stopIdx);
    if (alt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tripNoAlternative)),
      );
      return;
    }
    setState(() => plan.days[dayIdx].stops[stopIdx] = stop.withCandidate(alt));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Feuille dense : texte un peu plus petit que dans le reste de l'app,
    // en gardant le reglage de taille de police du telephone, borne a 1.15
    // (au-dela, « Changer » et « Autre proposition » debordaient).
    final scale = mq.textScaler.clamp(maxScaleFactor: 1.15).scale(1);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(scale * 0.92),
      ),
      child: _sheet(context),
    );
  }

  Widget _sheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
                  child: _step == _Step.plan ? _planView() : _question(),
                ),
              ),
            ),
            if (_step != _Step.plan) _footer(),
          ],
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
              _step == _Step.group ? Icons.close_rounded : Icons.arrow_back_rounded,
              color: FoodTokens.ink,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.tripPlanTitle,
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

  Widget _question() {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: switch (_step) {
        _Step.group => [
            _title(l.tripQWho, l.tripQWhoSub),
            _option('💑', l.tripCouple, l.tripCoupleSub,
                _group == TripGroup.couple,
                () => setState(() => _group = TripGroup.couple)),
            _option('👨‍👩‍👧', l.tripFamilyKids, l.tripFamilyKidsSub,
                _group == TripGroup.famille,
                () => setState(() => _group = TripGroup.famille)),
            _option('🎉', l.tripFriends, l.tripFriendsSub,
                _group == TripGroup.amis,
                () => setState(() => _group = TripGroup.amis)),
          ],
        _Step.people => [
            _title(l.tripQHowMany,
                _group == TripGroup.famille ? l.tripKidsIncluded : l.tripYouIncluded),
            const SizedBox(height: 12),
            _stepper(
              value: _people,
              label: l.tripPeople(_people),
              onMinus: _people > 2 ? () => setState(() => _people--) : null,
              onPlus: _people < 30 ? () => setState(() => _people++) : null,
            ),
          ],
        _Step.days => [
            _title(l.tripQDuration, l.tripQDurationSub),
            for (final d in const [1, 2, 3, 4, 5, 7])
              _option(
                d == 1 ? '☀️' : d == 7 ? '🧳' : '📅',
                _durationLabel(d),
                d == 2 ? l.tripWeekend : null,
                _days == d,
                () => setState(() => _days = d),
              ),
          ],
        _Step.meals => [
            _title(l.tripQMeals, l.tripQMealsSub),
            _option('🥐', l.tripMorning, l.tripMorningSub,
                _meals.contains(TripMeal.matin), () => _toggleMeal(TripMeal.matin)),
            _option('🍽️', l.tripNoon, l.tripNoonSub,
                _meals.contains(TripMeal.midi), () => _toggleMeal(TripMeal.midi)),
            _option('🌙', l.tripEvening, l.tripEveningSub,
                _meals.contains(TripMeal.soir), () => _toggleMeal(TripMeal.soir)),
          ],
        _Step.activities => [
            _title(l.tripQActivities,
                _group == TripGroup.famille
                    ? l.tripQActivitiesSubKids
                    : l.tripQActivitiesSub),
            _option('🎯', l.tripYesActivities, l.tripYesActivitiesSub,
                _activities == true, () => setState(() => _activities = true)),
            _option('🍴', l.tripNoActivities, null,
                _activities == false, () => setState(() => _activities = false)),
            if (_flow.last == _Step.activities && _activities != null && !_hasSomething)
              _warning(),
          ],
        _Step.night => [
            _title(l.tripQNight, l.tripQNightSub),
            _option('🍸', l.tripNightBar, l.tripNightBarSub,
                _night == TripNight.bar, () => setState(() => _night = TripNight.bar)),
            _option('💃', l.tripNightClub, l.tripNightClubSub,
                _night == TripNight.barClub,
                () => setState(() => _night = TripNight.barClub)),
            _option('😴', l.tripNightNone, null,
                _night == TripNight.none, () => setState(() => _night = TripNight.none)),
            if (_night != null && !_hasSomething) _warning(),
          ],
        _Step.music => [
            _title(l.tripQMusic, l.tripQMusicSub),
            for (final (m, emoji, label, sub) in [
              (TripMusic.electro, '🎧', l.tripMusicElectro, l.tripMusicElectroSub),
              (TripMusic.hiphop, '🎤', l.tripMusicHiphop, l.tripMusicHiphopSub),
              (TripMusic.latino, '🎺', l.tripMusicLatino, l.tripMusicLatinoSub),
              (TripMusic.generaliste, '🎶', l.tripMusicGeneral, l.tripMusicGeneralSub),
              (TripMusic.rock, '🎸', l.tripMusicRock, l.tripMusicRockSub),
              (TripMusic.any, '🤷', l.tripMusicAny, null),
            ])
              _option(emoji, label, sub, _music.contains(m),
                  () => setState(() => _toggleMusic(m))),
          ],
        _Step.plan => const [],
      },
    );
  }

  String _durationLabel(int d) {
    final l = context.l10n;
    return d == 1 ? l.tripOneDay : d == 7 ? l.tripOneWeek : l.tripDays(d);
  }

  Widget _warning() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(context.l10n.tripPickOne,
            style: FoodTokens.meta(color: FoodTokens.red)),
      );

  void _toggleMeal(TripMeal m) => setState(() {
        _meals.contains(m) ? _meals.remove(m) : _meals.add(m);
      });

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

  Widget _option(String emoji, String label, String? sub, bool selected, VoidCallback onTap) {
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
              color: selected ? AppColors.magenta : FoodTokens.stroke,
            ),
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
                    Text(label,
                        style: FoodTokens.bannerTitle().copyWith(
                          fontSize: 13.5,
                          color: selected ? Colors.white : FoodTokens.ink,
                        )),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub,
                          style: FoodTokens.meta(
                            color: selected ? Colors.white70 : FoodTokens.muted,
                          )),
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

  Widget _stepper({
    required int value,
    required String label,
    VoidCallback? onMinus,
    VoidCallback? onPlus,
  }) {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: onTap == null ? FoodTokens.hairline : AppColors.magenta,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 20, color: onTap == null ? FoodTokens.dim : Colors.white),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn(Icons.remove_rounded, onMinus),
        SizedBox(
          width: 130,
          child: Text(label,
              textAlign: TextAlign.center,
              style: FoodTokens.sectionHeader(fontSize: 18)),
        ),
        btn(Icons.add_rounded, onPlus),
      ],
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
            color: enabled ? AppColors.magenta : FoodTokens.stroke,
            borderRadius: BorderRadius.circular(FoodTokens.rPill),
            boxShadow: enabled ? _accentShadow : null,
          ),
          child: Text(
            isLast ? context.l10n.tripSeePlan : context.l10n.commonNext,
            style: FoodTokens.bannerTitle().copyWith(
              fontSize: 14,
              color: enabled ? Colors.white : FoodTokens.dim,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Feuille de route ──────────────────────────────────────────────────

  Widget _planView() {
    final plan = _plan;
    if (plan == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.magenta));
    }
    if (plan.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.tripNotEnough(widget.ville),
            textAlign: TextAlign.center,
            style: FoodTokens.body(),
          ),
        ),
      );
    }
    final a = plan.answers;
    final l = context.l10n;
    final groupLabel = switch (a.group) {
      TripGroup.couple => l.tripCouple,
      TripGroup.famille => l.tripFamily,
      TripGroup.amis => l.tripFriends,
    };
    final duree = _durationLabel(a.days);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        Text(l.tripYourTrip(widget.ville), style: FoodTokens.sectionHeader(fontSize: 18)),
        const SizedBox(height: 6),
        Text(l.tripSummary(groupLabel, a.people, duree),
            style: FoodTokens.meta(color: AppColors.magenta, w: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l.tripTapHint, style: FoodTokens.meta()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _pillButton(Icons.shuffle_rounded, l.tripOtherProposal, _reshuffle)),
            const SizedBox(width: 10),
            Expanded(
              child: _pillButton(Icons.tune_rounded, l.commonEdit,
                  () => setState(() => _step = _Step.group), outlined: true),
            ),
          ],
        ),
        for (var d = 0; d < plan.days.length; d++) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.days.length == 1 ? l.tripYourDay : l.tripDay(plan.days[d].index),
                  style: FoodTokens.eyebrow().copyWith(color: AppColors.magenta),
                ),
              ),
              if (_routeUri(plan.days[d]) != null)
                GestureDetector(
                  onTap: () => launchUrl(_routeUri(plan.days[d])!,
                      mode: LaunchMode.externalApplication),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, size: 15, color: AppColors.magenta),
                      const SizedBox(width: 4),
                      Text(l.tripDayRoute,
                          style: FoodTokens.meta(color: AppColors.magenta, w: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.days[d].stops.isEmpty)
            Text(l.tripNoMoreForDay, style: FoodTokens.meta())
          else
            for (var s = 0; s < plan.days[d].stops.length; s++)
              _StopCard(
                stop: plan.days[d].stops[s],
                people: a.people,
                kmFromPrevious: s == 0 ? null : _kmBetween(plan.days[d].stops[s - 1], plan.days[d].stops[s]),
                onOpen: () => CommerceRowCard.openDetail(
                  context,
                  plan.days[d].stops[s].candidate.commerce,
                ),
                onSwap: () => _swap(d, s),
              ),
        ],
      ],
    );
  }

  static double? _kmBetween(TripStop a, TripStop b) {
    final ca = a.candidate.commerce, cb = b.candidate.commerce;
    if (ca.latitude == 0 || cb.latitude == 0) return null;
    return TripPools.distanceKm(ca.latitude, ca.longitude, cb.latitude, cb.longitude);
  }

  /// Google Maps a pied, de la 1re a la derniere etape geolocalisee du jour.
  static Uri? _routeUri(TripDay day) {
    final pts = day.stops
        .map((s) => s.candidate.commerce)
        .where((c) => c.latitude != 0 && c.longitude != 0)
        .map((c) => '${c.latitude},${c.longitude}')
        .toList();
    if (pts.length < 2) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'travelmode': 'walking',
      'origin': pts.first,
      'destination': pts.last,
      if (pts.length > 2) 'waypoints': pts.sublist(1, pts.length - 1).join('|'),
    });
  }

  Widget _pillButton(IconData icon, String label, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: outlined ? FoodTokens.surface : AppColors.magenta,
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(color: outlined ? FoodTokens.stroke : AppColors.magenta),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: outlined ? AppColors.magenta : Colors.white),
            const SizedBox(width: 6),
            // Reduit le texte plutot que de deborder du bouton.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: FoodTokens.meta(
                      color: outlined ? AppColors.magenta : Colors.white,
                      w: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ombre des boutons actifs, aux couleurs de l'app (et non le vert de Food).
const _accentShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x59E91E63),
    blurRadius: 14,
    spreadRadius: -6,
    offset: Offset(0, 6),
  ),
];

class _StopCard extends StatelessWidget {
  final TripStop stop;
  final int people;
  final double? kmFromPrevious;
  final VoidCallback onOpen;
  final VoidCallback onSwap;

  const _StopCard({
    required this.stop,
    required this.people,
    this.kmFromPrevious,
    required this.onOpen,
    required this.onSwap,
  });

  static const _emoji = {
    TripStopKind.breakfast: '🥐',
    TripStopKind.lunch: '🍽️',
    TripStopKind.dinner: '🌙',
    TripStopKind.activity: '🎯',
    TripStopKind.drink: '🍸',
    TripStopKind.club: '💃',
  };

  /// « à 5 min à pied » sous 2 km (~80 m/min), sinon la distance en km.
  String? _distanceLabel(BuildContext context) {
    final km = kmFromPrevious;
    if (km == null) return null;
    final l = context.l10n;
    if (km < 2) return l.tripWalkMinutes((km * 1000 / 80).ceil());
    final sep = Localizations.localeOf(context).languageCode == 'en' ? '.' : ',';
    return l.tripKmFrom(km.toStringAsFixed(1).replaceAll('.', sep));
  }

  String _slotLabel(BuildContext context) {
    final l = context.l10n;
    return switch (stop.slot) {
      TripPlannerService.slotBreakfast => l.tripSlotBreakfast,
      TripPlannerService.slotMorning => l.tripSlotMorning,
      TripPlannerService.slotLunch => l.tripSlotLunch,
      TripPlannerService.slotAfternoon => l.tripSlotAfternoon,
      TripPlannerService.slotDinner => l.tripSlotDinner,
      TripPlannerService.slotDrink => l.tripSlotDrink,
      TripPlannerService.slotClub => l.tripSlotClub,
      _ => stop.slot,
    };
  }

  bool get _isMeal =>
      stop.kind == TripStopKind.lunch || stop.kind == TripStopKind.dinner;

  @override
  Widget build(BuildContext context) {
    final c = stop.candidate.commerce;
    final hasPhoto = c.photo.startsWith('http');
    final emoji = Container(
      color: const Color(0x1FE91E63),
      alignment: Alignment.center,
      child: Text(_emoji[stop.kind]!, style: const TextStyle(fontSize: 20)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FoodTokens.surface,
            borderRadius: BorderRadius.circular(FoodTokens.rCard),
            border: Border.all(color: FoodTokens.hairline),
            boxShadow: FoodTokens.banner,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: c.photo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => emoji,
                          placeholder: (_, __) => emoji,
                        )
                      : emoji,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_emoji[stop.kind]} ${_slotLabel(context)}'.toUpperCase(),
                        style: FoodTokens.tinyTag(color: AppColors.violet)),
                    const SizedBox(height: 5),
                    Text(c.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.bannerTitle().copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (c.categorie.isNotEmpty)
                          anyCategoryLabel(context, c.categorie),
                        if (stop.candidate.isPartner) context.l10n.tripPartner,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.meta(),
                    ),
                    if (_distanceLabel(context) != null)
                      Text('🚶 ${_distanceLabel(context)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FoodTokens.meta(color: AppColors.violet)),
                    if (_isMeal && people >= 6)
                      Text(context.l10n.tripBookingAdvised(people),
                          style: FoodTokens.meta(color: AppColors.magenta, w: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Boutons explicites : toucher la carte ouvrait deja la fiche,
              // mais rien ne l'indiquait.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniAction(
                    icon: Icons.info_outline_rounded,
                    label: context.l10n.tripInfos,
                    filled: true,
                    onTap: onOpen,
                  ),
                  const SizedBox(height: 6),
                  _MiniAction(
                    icon: Icons.autorenew_rounded,
                    label: context.l10n.tripChange,
                    onTap: onSwap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit bouton icone + libelle de la carte d'etape (Infos / Changer).
class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.magenta;
    return Material(
      color: filled ? AppColors.magenta : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.magenta.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          width: 86,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 4),
              // Reduit le texte plutot que de deborder du bouton.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: FoodTokens.meta(color: fg, w: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
