import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';
import 'package:pulz_app/features/day/state/boost_availability_provider.dart';
import 'package:pulz_app/features/day/state/boost_prices_provider.dart';

/// Etape 1 — Optionnel.
/// Tout ce qui n'est pas obligatoire pour publier : description, recurrence,
/// prix variations, billetterie, organisateur, public/niveau, tags, boost.
/// Organise en sections pliables pour ne pas overwhelm le user.
class StepDetails extends ConsumerStatefulWidget {
  const StepDetails({super.key});

  @override
  ConsumerState<StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends ConsumerState<StepDetails> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);

  late final TextEditingController _descCourteController;
  late final TextEditingController _descLongueController;
  late final TextEditingController _prixReduitController;
  late final TextEditingController _prixGroupeController;
  late final TextEditingController _prixEarlyBirdController;
  late final TextEditingController _lienBilletterieController;
  late final TextEditingController _lieuNomController;
  late final TextEditingController _orgNomController;
  late final TextEditingController _orgEmailController;
  late final TextEditingController _orgTelController;
  late final TextEditingController _orgSiteController;
  late final TextEditingController _participantsMinController;
  late final TextEditingController _participantsMaxController;
  late final TextEditingController _tagController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _descCourteController = TextEditingController();
    _descLongueController = TextEditingController();
    _prixReduitController = TextEditingController();
    _prixGroupeController = TextEditingController();
    _prixEarlyBirdController = TextEditingController();
    _lienBilletterieController = TextEditingController();
    _lieuNomController = TextEditingController();
    _orgNomController = TextEditingController();
    _orgEmailController = TextEditingController();
    _orgTelController = TextEditingController();
    _orgSiteController = TextEditingController();
    _participantsMinController = TextEditingController();
    _participantsMaxController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _descCourteController.dispose();
    _descLongueController.dispose();
    _prixReduitController.dispose();
    _prixGroupeController.dispose();
    _prixEarlyBirdController.dispose();
    _lienBilletterieController.dispose();
    _lieuNomController.dispose();
    _orgNomController.dispose();
    _orgEmailController.dispose();
    _orgTelController.dispose();
    _orgSiteController.dispose();
    _participantsMinController.dispose();
    _participantsMaxController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _syncFromState(CreateEventState s) {
    _descCourteController.text = s.descriptionCourte;
    _descLongueController.text = s.descriptionLongue;
    _prixReduitController.text = s.prixReduit;
    _prixGroupeController.text = s.prixGroupe;
    _prixEarlyBirdController.text = s.prixEarlyBird;
    _lienBilletterieController.text = s.lienBilletterie;
    _lieuNomController.text = s.lieuNom ?? '';
    _orgNomController.text = s.organisateurNom;
    _orgEmailController.text = s.organisateurEmail;
    _orgTelController.text = s.organisateurTelephone;
    _orgSiteController.text = s.organisateurSite;
    _participantsMinController.text = s.participantsMin;
    _participantsMaxController.text = s.participantsMax;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    if (!_initialized) {
      _initialized = true;
      _syncFromState(state);
    }

    ref.listen<CreateEventState>(createEventProvider, (prev, next) {
      if (prev != null && prev.prefillRevision != next.prefillRevision) {
        _syncFromState(next);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Plus d\'infos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Optionnel',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Affine ton event ou clique "Publier" maintenant.',
            style: TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
          const SizedBox(height: 14),

          // Boost (mis en avant en premier, c'est ce qui rapporte au pro)
          _BoostSection(state: state, notifier: notifier),
          const SizedBox(height: 12),

          // Description
          _Section(
            title: 'Description',
            icon: Icons.description_outlined,
            initiallyExpanded: true,
            children: [
              TextFormField(
                controller: _descCourteController,
                decoration: _input('Description courte (1-2 lignes)'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                maxLines: 2,
                onChanged: notifier.updateDescriptionCourte,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descLongueController,
                decoration: _input('Description longue'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                maxLines: 5,
                onChanged: notifier.updateDescriptionLongue,
              ),
            ],
          ),

          // Dates / récurrence
          _Section(
            title: 'Dates et récurrence',
            icon: Icons.event_repeat_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Date fin',
                      value: state.dateFin,
                      onPicked: notifier.updateDateFin,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeButton(
                      label: 'Heure fin',
                      value: state.heureFin,
                      onPicked: notifier.updateHeureFin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Quotidien', 'Hebdomadaire', 'Mensuel'].map((r) {
                  final selected = state.recurrenceType == r.toLowerCase();
                  return FilterChip(
                    label: Text(r, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (v) => notifier.updateRecurrenceType(
                      v ? r.toLowerCase() : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Lieu détaillé
          _Section(
            title: 'Lieu détaillé',
            icon: Icons.place_outlined,
            children: [
              TextFormField(
                controller: _lieuNomController,
                decoration: _input('Nom du lieu (ex. salle des fêtes)'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                onChanged: notifier.updateLieuNom,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kLieuTypes.map((lt) {
                  final selected = state.lieuType == lt;
                  return ChoiceChip(
                    label: Text(lt, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => notifier.updateLieuType(lt),
                  );
                }).toList(),
              ),
            ],
          ),

          // Tarification avancée + billetterie
          _Section(
            title: 'Tarification & billetterie',
            icon: Icons.confirmation_number_outlined,
            children: [
              if (!state.estGratuit) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prixReduitController,
                        decoration: _input('Tarif réduit'),
                        style: TextStyle(fontSize: 13, color: AppColors.text),
                        keyboardType: TextInputType.number,
                        onChanged: notifier.updatePrixReduit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _prixGroupeController,
                        decoration: _input('Tarif groupe'),
                        style: TextStyle(fontSize: 13, color: AppColors.text),
                        keyboardType: TextInputType.number,
                        onChanged: notifier.updatePrixGroupe,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _prixEarlyBirdController,
                  decoration: _input('Early bird'),
                  style: TextStyle(fontSize: 13, color: AppColors.text),
                  keyboardType: TextInputType.number,
                  onChanged: notifier.updatePrixEarlyBird,
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _lienBilletterieController,
                decoration: _input('Lien billetterie (https://...)'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                keyboardType: TextInputType.url,
                onChanged: notifier.updateLienBilletterie,
              ),
            ],
          ),

          // Organisateur
          _Section(
            title: 'Organisateur',
            icon: Icons.person_outline,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kOrganisateurTypes.map((t) {
                  final selected = state.organisateurType == t;
                  return ChoiceChip(
                    label: Text(t, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => notifier.updateOrganisateurType(t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orgNomController,
                decoration: _input('Nom'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                onChanged: notifier.updateOrganisateurNom,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orgEmailController,
                decoration: _input('Email'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                keyboardType: TextInputType.emailAddress,
                onChanged: notifier.updateOrganisateurEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orgTelController,
                decoration: _input('Téléphone'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                keyboardType: TextInputType.phone,
                onChanged: notifier.updateOrganisateurTelephone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orgSiteController,
                decoration: _input('Site web'),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                keyboardType: TextInputType.url,
                onChanged: notifier.updateOrganisateurSite,
              ),
            ],
          ),

          // Public & participants
          _Section(
            title: 'Public & participants',
            icon: Icons.group_outlined,
            children: [
              _labelSmall('Public cible'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kPublicCible.map((p) {
                  final selected = state.publicCible == p;
                  return ChoiceChip(
                    label: Text(p, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => notifier.updatePublicCible(p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _labelSmall('Niveau'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kNiveaux.map((n) {
                  final selected = state.niveau == n;
                  return ChoiceChip(
                    label: Text(n, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => notifier.updateNiveau(n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _participantsMinController,
                      decoration: _input('Min'),
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      keyboardType: TextInputType.number,
                      onChanged: notifier.updateParticipantsMin,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _participantsMaxController,
                      decoration: _input('Max'),
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      keyboardType: TextInputType.number,
                      onChanged: notifier.updateParticipantsMax,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _labelSmall('Inscription'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kInscriptionTypes.map((i) {
                  final selected = state.inscriptionType == i;
                  return ChoiceChip(
                    label: Text(i, style: TextStyle(fontSize: 11, color: AppColors.text)),
                    selected: selected,
                    selectedColor: _primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _primaryColor,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => notifier.updateInscriptionType(i),
                  );
                }).toList(),
              ),
            ],
          ),

          // Tags
          _Section(
            title: 'Tags',
            icon: Icons.tag_outlined,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...state.tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          final next = List<String>.from(state.tags)..remove(tag);
                          notifier.updateTags(next);
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: _input('Ajouter un tag'),
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isEmpty || state.tags.contains(t) || state.tags.length >= 10) return;
                        notifier.updateTags([...state.tags, t]);
                        _tagController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, color: _primaryColor),
                    onPressed: () {
                      final t = _tagController.text.trim();
                      if (t.isEmpty || state.tags.contains(t) || state.tags.length >= 10) return;
                      notifier.updateTags([...state.tags, t]);
                      _tagController.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  static Widget _labelSmall(String text) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkColor),
      );

  static InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: AppColors.textFaint),
      filled: true,
      fillColor: AppColors.surfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Section pliable
// ──────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, size: 18, color: const Color(0xFF4A1259)),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A1259),
            ),
          ),
          iconColor: AppColors.textDim,
          collapsedIconColor: AppColors.textDim,
          children: children,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Boost section (option payante de mise en avant)
// ──────────────────────────────────────────────────────────────────────────

class _BoostSection extends ConsumerWidget {
  final CreateEventState state;
  final CreateEventNotifier notifier;

  const _BoostSection({required this.state, required this.notifier});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _boostColors = <String, Color>{
    'P1': Color(0xFFFF6B00),
    'P2': Color(0xFFE91E8C),
    'P3': Color(0xFF7B2D8E),
  };
  static const _boostIcons = <String, IconData>{
    'P1': Icons.rocket_launch,
    'P2': Icons.trending_up,
    'P3': Icons.visibility,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(boostPricesProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B00).withValues(alpha: 0.08),
            const Color(0xFFE91E8C).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, size: 16, color: Color(0xFFFF6B00)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Booster ton event',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'OPTIONNEL',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFFF6B00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Augmente la visibilité de ton event',
            style: TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
          const SizedBox(height: 12),
          pricesAsync.when(
            data: (prices) => Column(
              children: prices.map((bp) {
                final color = _boostColors[bp.priority] ?? _primaryColor;
                final icon = _boostIcons[bp.priority] ?? Icons.star;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BoostOption(
                    label: bp.label,
                    price: bp.priceLabel,
                    description: bp.description,
                    color: color,
                    icon: icon,
                    isSelected: state.priority == bp.priority,
                    onTap: () => notifier.updatePriority(
                      state.priority == bp.priority ? 'P4' : bp.priority,
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Text(
              'Erreur chargement prix',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          ),
          if (state.priority != 'P4' && state.priority != 'P3') ...[
            const SizedBox(height: 12),
            _DaysSelector(state: state, notifier: notifier),
          ],
        ],
      ),
    );
  }
}

class _BoostOption extends StatelessWidget {
  final String label;
  final String price;
  final String description;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoostOption({
    required this.label,
    required this.price,
    required this.description,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaysSelector extends ConsumerWidget {
  final CreateEventState state;
  final CreateEventNotifier notifier;

  const _DaysSelector({required this.state, required this.notifier});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(boostPricesProvider);
    final selectedDates = state.boostDates;
    final count = selectedDates.length;
    final priority = state.priority;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final availAsync = ref.watch(boostAvailabilityProvider(AvailabilityParams(
      priority: priority,
      startDate: today,
      endDate: today.add(const Duration(days: 30)),
    )));

    return pricesAsync.when(
      data: (prices) {
        final bp = prices.where((p) => p.priority == priority).firstOrNull;
        if (bp == null) return const SizedBox.shrink();
        final total = (bp.amountCents * (count > 0 ? count : 0) / 100).toStringAsFixed(0);
        final color = _BoostSection._boostColors[priority] ?? const Color(0xFF7B2D8E);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Touche les jours souhaités',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                  if (count > 0)
                    GestureDetector(
                      onTap: () => notifier.clearBoostDates(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Effacer',
                          style: TextStyle(fontSize: 10, color: AppColors.textDim),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              availAsync.when(
                data: (avail) => SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avail.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, i) {
                      final day = avail[i];
                      final isSelected = selectedDates.any((d) => _isSameDay(d, day.date));
                      final dayColor = day.isFull
                          ? Colors.red.shade400
                          : day.available <= 1
                              ? Colors.orange
                              : Colors.green.shade400;
                      return GestureDetector(
                        onTap: day.isFull ? null : () => notifier.toggleBoostDate(day.date),
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : (day.isFull ? Colors.grey.shade100 : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : AppColors.line,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.date.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (day.isFull
                                          ? AppColors.textFaint
                                          : const Color(0xFF1A1A2E)),
                                ),
                              ),
                              Text(
                                DateFormat('MMM', 'fr_FR').format(day.date),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isSelected ? Colors.white70 : AppColors.textFaint,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 18,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: isSelected ? Colors.white70 : dayColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const Text(
                  'Erreur chargement',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$count jour${count > 1 ? 's' : ''} x ${bp.amountCents ~/ 100}€',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDim,
                          ),
                        ),
                      ),
                      Text(
                        '$total€',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Date / Time pickers compacts pour les sections optionnelles
// ──────────────────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? today,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? _primaryColor.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primaryColor.withValues(alpha: 0.3) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue ? DateFormat('d MMM', 'fr_FR').format(value!) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: () => onPicked(null),
                child: Icon(Icons.close, size: 14, color: AppColors.textFaint),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onPicked;

  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? _primaryColor.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primaryColor.withValues(alpha: 0.3) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue
                    ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: () => onPicked(null),
                child: Icon(Icons.close, size: 14, color: AppColors.textFaint),
              ),
          ],
        ),
      ),
    );
  }
}
