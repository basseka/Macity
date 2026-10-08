import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/trip_planner/data/trip_planner_service.dart';
import 'package:pulz_app/features/trip_planner/domain/trip_plan.dart';

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

enum _Step { group, people, days, meals, activities, night, plan }

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
        _ => true,
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
        const SnackBar(content: Text('Pas d\'autre lieu disponible pour cette étape')),
      );
      return;
    }
    setState(() => plan.days[dayIdx].stops[stopIdx] = stop.withCandidate(alt));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Feuille dense : texte un peu plus petit que dans le reste de l'app,
    // en gardant le reglage de taille de police du telephone.
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(mq.textScaler.scale(1) * 0.92),
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
              'Organiser mon trip',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: switch (_step) {
        _Step.group => [
            _title('Vous partez avec qui ?', 'On adapte les adresses à votre groupe.'),
            _option('💑', 'En couple', 'Tables romantiques, sorties à deux',
                _group == TripGroup.couple,
                () => setState(() => _group = TripGroup.couple)),
            _option('👨‍👩‍👧', 'En famille avec enfants', 'Adresses et activités adaptées aux enfants',
                _group == TripGroup.famille,
                () => setState(() => _group = TripGroup.famille)),
            _option('🎉', 'Entre amis', 'Tables à partager, activités fun, un verre le soir',
                _group == TripGroup.amis,
                () => setState(() => _group = TripGroup.amis)),
          ],
        _Step.people => [
            _title('Combien êtes-vous ?',
                _group == TripGroup.famille ? 'Enfants compris.' : 'Vous compris.'),
            const SizedBox(height: 12),
            _stepper(
              value: _people,
              label: '$_people personnes',
              onMinus: _people > 2 ? () => setState(() => _people--) : null,
              onPlus: _people < 30 ? () => setState(() => _people++) : null,
            ),
          ],
        _Step.days => [
            _title('Vous restez combien de temps ?', 'Une feuille de route par jour.'),
            for (final d in const [1, 2, 3, 4, 5, 7])
              _option(
                d == 1 ? '☀️' : d == 7 ? '🧳' : '📅',
                d == 1 ? '1 journée' : d == 7 ? '1 semaine' : '$d jours',
                d == 2 ? 'Le week-end' : null,
                _days == d,
                () => setState(() => _days = d),
              ),
          ],
        _Step.meals => [
            _title('Vous mangez dehors quand ?', 'Touchez pour cocher ou décocher.'),
            _option('🥐', 'Le matin', 'Brunch, salon de thé',
                _meals.contains(TripMeal.matin), () => _toggleMeal(TripMeal.matin)),
            _option('🍽️', 'Le midi', 'Déjeuner',
                _meals.contains(TripMeal.midi), () => _toggleMeal(TripMeal.midi)),
            _option('🌙', 'Le soir', 'Dîner',
                _meals.contains(TripMeal.soir), () => _toggleMeal(TripMeal.soir)),
          ],
        _Step.activities => [
            _title('Voulez-vous des activités ?',
                _group == TripGroup.famille
                    ? 'Sorties pour petits et grands entre les repas.'
                    : 'Sorties et visites entre les repas.'),
            _option('🎯', 'Oui, des activités', 'Une le matin, une l\'après-midi',
                _activities == true, () => setState(() => _activities = true)),
            _option('🍴', 'Non, juste les repas', null,
                _activities == false, () => setState(() => _activities = false)),
            if (_flow.last == _Step.activities && _activities != null && !_hasSomething)
              _warning(),
          ],
        _Step.night => [
            _title('Et la soirée ?', 'Après le dîner, dans le même quartier.'),
            _option('🍸', 'Un verre en bar', 'Bar à cocktails, pub, bar de nuit',
                _night == TripNight.bar, () => setState(() => _night = TripNight.bar)),
            _option('🪩', 'Bar puis discothèque', 'Pour finir la nuit en club',
                _night == TripNight.barClub,
                () => setState(() => _night = TripNight.barClub)),
            _option('😴', 'Pas de sortie', null,
                _night == TripNight.none, () => setState(() => _night = TripNight.none)),
            if (_night != null && !_hasSomething) _warning(),
          ],
        _Step.plan => const [],
      },
    );
  }

  Widget _warning() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Choisissez au moins un repas, une activité ou une sortie.',
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
            color: selected ? FoodTokens.forest : FoodTokens.surface,
            borderRadius: BorderRadius.circular(FoodTokens.rCard),
            border: Border.all(
              color: selected ? FoodTokens.forest : FoodTokens.stroke,
            ),
            boxShadow: selected ? FoodTokens.ctaPill() : null,
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
                color: selected ? FoodTokens.teal : FoodTokens.dim,
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
              color: onTap == null ? FoodTokens.hairline : FoodTokens.forest,
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
            color: enabled ? FoodTokens.forest : FoodTokens.stroke,
            borderRadius: BorderRadius.circular(FoodTokens.rPill),
            boxShadow: enabled ? FoodTokens.ctaPill() : null,
          ),
          child: Text(
            isLast ? 'Voir ma feuille de route' : 'Suivant',
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
      return const Center(child: CircularProgressIndicator(color: FoodTokens.forest));
    }
    if (plan.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Pas encore assez d\'adresses à ${widget.ville} pour composer un trip. '
            'Revenez bientôt !',
            textAlign: TextAlign.center,
            style: FoodTokens.body(),
          ),
        ),
      );
    }
    final a = plan.answers;
    final groupLabel = switch (a.group) {
      TripGroup.couple => 'En couple',
      TripGroup.famille => 'En famille',
      TripGroup.amis => 'Entre amis',
    };
    final duree = a.days == 1 ? '1 journée' : a.days == 7 ? '1 semaine' : '${a.days} jours';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        Text('Votre trip à ${widget.ville}', style: FoodTokens.sectionHeader(fontSize: 18)),
        const SizedBox(height: 6),
        Text('$groupLabel · ${a.people} pers. · $duree',
            style: FoodTokens.meta(color: FoodTokens.forest, w: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Touchez une adresse pour voir sa fiche.', style: FoodTokens.meta()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _pillButton(Icons.shuffle_rounded, 'Autre proposition', _reshuffle)),
            const SizedBox(width: 10),
            Expanded(
              child: _pillButton(Icons.tune_rounded, 'Modifier',
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
                  plan.days.length == 1 ? 'Votre journée' : 'Jour ${plan.days[d].index}',
                  style: FoodTokens.eyebrow(),
                ),
              ),
              if (_routeUri(plan.days[d]) != null)
                GestureDetector(
                  onTap: () => launchUrl(_routeUri(plan.days[d])!,
                      mode: LaunchMode.externalApplication),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, size: 15, color: FoodTokens.forest),
                      const SizedBox(width: 4),
                      Text('Itinéraire du jour',
                          style: FoodTokens.meta(color: FoodTokens.forest, w: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.days[d].stops.isEmpty)
            Text('Plus d\'adresses disponibles pour ce jour.', style: FoodTokens.meta())
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
          color: outlined ? FoodTokens.surface : FoodTokens.forest,
          borderRadius: BorderRadius.circular(FoodTokens.rPill),
          border: Border.all(color: outlined ? FoodTokens.stroke : FoodTokens.forest),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: outlined ? FoodTokens.forest : Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: FoodTokens.meta(
                  color: outlined ? FoodTokens.forest : Colors.white,
                  w: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

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
    TripStopKind.club: '🪩',
  };

  /// « à 5 min à pied » sous 2 km (~80 m/min), sinon la distance en km.
  String? get _distanceLabel {
    final km = kmFromPrevious;
    if (km == null) return null;
    if (km < 2) return 'à ${(km * 1000 / 80).ceil()} min à pied de l\'étape précédente';
    return 'à ${km.toStringAsFixed(1).replaceAll('.', ',')} km de l\'étape précédente';
  }

  bool get _isMeal =>
      stop.kind == TripStopKind.lunch || stop.kind == TripStopKind.dinner;

  @override
  Widget build(BuildContext context) {
    final c = stop.candidate.commerce;
    final hasPhoto = c.photo.startsWith('http');
    final emoji = Container(
      color: const Color(0x1F2BAB9A),
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
                    Text('${_emoji[stop.kind]} ${stop.slot}'.toUpperCase(),
                        style: FoodTokens.tinyTag(color: FoodTokens.teal)),
                    const SizedBox(height: 5),
                    Text(c.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.bannerTitle().copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (c.categorie.isNotEmpty) c.categorie,
                        if (stop.candidate.isPartner) '⭐ Partenaire',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.meta(),
                    ),
                    if (_distanceLabel != null)
                      Text('🚶 $_distanceLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FoodTokens.meta(color: FoodTokens.teal)),
                    if (_isMeal && people >= 6)
                      Text('Réservation conseillée pour $people',
                          style: FoodTokens.meta(color: FoodTokens.forest, w: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Changer',
                onPressed: onSwap,
                icon: const Icon(Icons.autorenew_rounded, color: FoodTokens.forest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
