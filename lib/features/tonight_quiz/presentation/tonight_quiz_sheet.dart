import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/reported_events/presentation/screens/tonight_bons_plans_page.dart';
import 'package:pulz_app/features/reported_events/state/tonight_events_provider.dart';
import 'package:pulz_app/features/tonight_quiz/data/tonight_quiz_service.dart';
import 'package:pulz_app/features/tonight_quiz/domain/tonight_quiz.dart';

/// « Quoi faire ce soir » (2026-10-21) : trois questions (avec qui, envies,
/// quand) puis des propositions par envie : events de ce soir, lieux de la
/// ville et balades du soir (trouvées par l'IA, table `night_walks`).
/// Le lien du bas ouvre toujours la liste complète des events du soir.
class TonightQuizSheet extends ConsumerStatefulWidget {
  final String ville;

  const TonightQuizSheet({super.key, required this.ville});

  static Future<void> show(BuildContext context, {required String ville}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TonightQuizSheet(ville: ville),
    );
  }

  @override
  ConsumerState<TonightQuizSheet> createState() => _TonightQuizSheetState();
}

enum _Step { group, wishes, when, results }

class _TonightQuizSheetState extends ConsumerState<TonightQuizSheet> {
  late final Future<TonightPools> _poolsFuture =
      TonightQuizService().loadPools(widget.ville);

  _Step _step = _Step.group;
  TonightGroup? _group;
  final Set<TonightWish> _wishes = {};
  TonightWhen? _when;

  List<TonightSection>? _sections;
  int _seed = DateTime.now().millisecondsSinceEpoch % 100000;

  static const _flow = [_Step.group, _Step.wishes, _Step.when];

  bool get _canContinue => switch (_step) {
        _Step.group => _group != null,
        _Step.wishes => _wishes.isNotEmpty,
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
      setState(() => _step = _Step.group);
      return;
    }
    final i = _flow.indexOf(_step);
    if (i > 0) {
      setState(() => _step = _flow[i - 1]);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _selectGroup(TonightGroup g) => setState(() {
        _group = g;
        // Envies plus proposées pour ce groupe (soirée, cocktail en famille).
        _wishes.retainAll(TonightPools.wishesFor(g));
      });

  Future<void> _generate() async {
    setState(() {
      _step = _Step.results;
      _sections = null;
    });
    final pools = await _poolsFuture;
    // Events de la soirée (>= 17 h) déjà chargés pour le compteur de la Home.
    await ref.read(tonightEventsProvider.future).catchError((_) => <Event>[]);
    if (!mounted) return;
    final events = ref.read(nightEventsProvider).valueOrNull ?? const <Event>[];
    setState(
      () => _sections = pools.build(
        TonightAnswers(group: _group!, wishes: {..._wishes}, when: _when!),
        events,
        seed: _seed,
      ),
    );
  }

  void _reshuffle() {
    _seed++;
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le provider des events du soir en vie pendant le questionnaire.
    ref.watch(nightEventsProvider);
    final mq = MediaQuery.of(context);
    // Même densité que « Organiser mon trip » : texte un peu réduit, borné.
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
              _step == _Step.group
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: FoodTokens.ink,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.tonightWhatToDo,
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

  static String wishEmoji(TonightWish w) => switch (w) {
        TonightWish.concert => '🎤',
        TonightWish.soiree => '🪩',
        TonightWish.cocktail => '🍸',
        TonightWish.balade => '🌙',
        TonightWish.activite => '🎳',
        TonightWish.spectacle => '🎭',
      };

  (String, String) _wishLabels(TonightWish w) {
    final l = context.l10n;
    return switch (w) {
      TonightWish.concert => (l.tqConcert, l.tqConcertSub),
      TonightWish.soiree => (l.tqParty, l.tqPartySub),
      TonightWish.cocktail => (l.tqCocktail, l.tqCocktailSub),
      TonightWish.balade => (l.tqWalk, l.tqWalkSub),
      TonightWish.activite => (l.tqActivity, l.tqActivitySub),
      TonightWish.spectacle => (l.tqShow, l.tqShowSub),
    };
  }

  Widget _question() {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: switch (_step) {
        _Step.group => [
            _title(l.tqQWho, l.tqQWhoSub),
            for (final (g, emoji, label, sub) in [
              (TonightGroup.solo, '🙋', l.tqSolo, l.tqSoloSub),
              (TonightGroup.couple, '💑', l.tqCouple, l.tqCoupleSub),
              (TonightGroup.amis, '🎉', l.tqFriends, l.tqFriendsSub),
              (TonightGroup.famille, '👨‍👩‍👧', l.tqFamily, l.tqFamilySub),
            ])
              _option(emoji, label, sub, _group == g, () => _selectGroup(g)),
          ],
        _Step.wishes => [
            _title(l.tqQWhat, l.tqQWhatSub),
            for (final w in TonightPools.wishesFor(_group ?? TonightGroup.solo))
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
        _Step.when => [
            _title(l.tqQWhen, l.tqQWhenSub),
            for (final (w, emoji, label, sub) in [
              (TonightWhen.now, '⚡', l.tqNow, l.tqNowSub),
              (
                TonightWhen.afterDinner,
                '🍽️',
                l.tqAfterDinner,
                l.tqAfterDinnerSub
              ),
              (TonightWhen.late, '🌃', l.tqLate, l.tqLateSub),
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
      return const Center(
          child: CircularProgressIndicator(color: AppColors.magenta));
    }
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        Text(l.tqYourEvening(widget.ville),
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
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => TonightBonsPlansPage.show(
              context,
              nightOnly: true,
              title: l.tonightWhatToDo,
            ),
            icon: const Icon(Icons.list_rounded, color: AppColors.magenta),
            label: Text(
              l.tqSeeAllEvents,
              style:
                  FoodTokens.meta(color: AppColors.magenta, w: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _section(TonightSection s) {
    final l = context.l10n;
    return [
      const SizedBox(height: 22),
      Text(
        '${wishEmoji(s.wish)}  ${_wishLabels(s.wish).$1}'.toUpperCase(),
        style: FoodTokens.eyebrow().copyWith(color: AppColors.magenta),
      ),
      const SizedBox(height: 10),
      if (s.isEmpty) Text(l.tqNothing(widget.ville), style: FoodTokens.meta()),
      if (s.events.isNotEmpty) ...[
        _subLabel(s.eventsOtherTime ? l.tqEventsOtherTime : l.tqEventsTonight),
        for (final e in s.events) _eventCard(e),
      ],
      if (s.places.isNotEmpty) ...[
        if (s.events.isNotEmpty) _subLabel(l.tqPlaces),
        for (final c in s.places) _placeCard(c),
      ],
      for (final w in s.walks) _walkCard(w),
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
    return _ResultCard(
      imageUrl: e.photoPath ?? '',
      emoji: '🎫',
      title: e.titre,
      lines: [
        [if (time.isNotEmpty) time, if (e.lieuNom.isNotEmpty) e.lieuNom]
            .join(' · '),
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

  Widget _placeCard(CommerceModel c) => _ResultCard(
        imageUrl: c.photo,
        emoji: '📍',
        title: c.nom,
        lines: [
          [
            if (c.categorie.isNotEmpty) anyCategoryLabel(context, c.categorie),
            if (c.isPartner) context.l10n.tripPartner,
          ].join(' · '),
        ],
        onTap: () => CommerceRowCard.openDetail(context, c),
      );

  Widget _walkCard(NightWalk w) {
    final l = context.l10n;
    final sep =
        Localizations.localeOf(context).languageCode == 'en' ? '.' : ',';
    final meta = [
      if (w.dureeMin > 0) l.tqMinutes(w.dureeMin),
      if (w.distanceKm > 0)
        '${w.distanceKm.toStringAsFixed(1).replaceAll('.', sep)} km',
    ].join(' · ');
    return _ResultCard(
      imageUrl: w.photo,
      emoji: '🌙',
      title: w.titre,
      lines: [
        if (meta.isNotEmpty) meta,
        if (w.depart.isNotEmpty) l.tqStartAt(w.depart),
      ],
      description: w.description,
      actionLabel: l.tqGoThere,
      onTap: () => _openWalk(w),
    );
  }

  /// Itinéraire à pied jusqu'au point de départ (GPS, sinon recherche).
  void _openWalk(NightWalk w) {
    final destination = w.latitude != 0 && w.longitude != 0
        ? '${w.latitude},${w.longitude}'
        : '${w.depart}, ${widget.ville}';
    launchUrl(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'travelmode': 'walking',
        'destination': destination,
      }),
      mode: LaunchMode.externalApplication,
    );
  }

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

/// Carte d'une proposition : vignette (photo ou emoji), titre, lignes
/// d'infos, description éventuelle (balades) et flèche ou bouton d'action.
class _ResultCard extends StatelessWidget {
  final String imageUrl;
  final String emoji;
  final String title;
  final List<String> lines;
  final String? description;
  final String? actionLabel;
  final VoidCallback onTap;

  const _ResultCard({
    required this.imageUrl,
    required this.emoji,
    required this.title,
    required this.lines,
    required this.onTap,
    this.description,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0x1FE91E63),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
    final visibleLines = lines.where((s) => s.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FoodTokens.surface,
            borderRadius: BorderRadius.circular(FoodTokens.rCard),
            border: Border.all(color: FoodTokens.hairline),
            boxShadow: FoodTokens.banner,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.bannerTitle().copyWith(fontSize: 13.5),
                    ),
                    for (final line in visibleLines) ...[
                      const SizedBox(height: 2),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.meta(),
                      ),
                    ],
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.meta(color: FoodTokens.inkSoft),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 15,
                            color: AppColors.magenta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            actionLabel!,
                            style: FoodTokens.meta(
                              color: AppColors.magenta,
                              w: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel == null)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child:
                      Icon(Icons.chevron_right_rounded, color: FoodTokens.dim),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
