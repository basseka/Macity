import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';

class StepDetails extends ConsumerStatefulWidget {
  const StepDetails({super.key});

  @override
  ConsumerState<StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends ConsumerState<StepDetails> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);
  late final TextEditingController _descLongueController;
  late final TextEditingController _orgNomController;
  late final TextEditingController _orgEmailController;
  late final TextEditingController _orgTelController;
  late final TextEditingController _orgSiteController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _descLongueController = TextEditingController();
    _orgNomController = TextEditingController();
    _orgEmailController = TextEditingController();
    _orgTelController = TextEditingController();
    _orgSiteController = TextEditingController();
    _minController = TextEditingController();
    _maxController = TextEditingController();
  }

  @override
  void dispose() {
    _descLongueController.dispose();
    _orgNomController.dispose();
    _orgEmailController.dispose();
    _orgTelController.dispose();
    _orgSiteController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    if (!_initialized) {
      _initialized = true;
      _descLongueController.text = state.descriptionLongue;
      _orgNomController.text = state.organisateurNom;
      _orgEmailController.text = state.organisateurEmail;
      _orgTelController.text = state.organisateurTelephone;
      _orgSiteController.text = state.organisateurSite;
      _minController.text = state.participantsMin;
      _maxController.text = state.participantsMax;
    }

    // Resync quand le wizard est pre-rempli (loadEvent / prefillFromScan).
    ref.listen<CreateEventState>(createEventProvider, (prev, next) {
      if (prev != null && prev.prefillRevision != next.prefillRevision) {
        _descLongueController.text = next.descriptionLongue;
        _orgNomController.text = next.organisateurNom;
        _orgEmailController.text = next.organisateurEmail;
        _orgTelController.text = next.organisateurTelephone;
        _orgSiteController.text = next.organisateurSite;
        _minController.text = next.participantsMin;
        _maxController.text = next.participantsMax;
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
                  'Details',
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
          const SizedBox(height: 14),

          // Description longue
          TextFormField(
            controller: _descLongueController,
            decoration: _inputDecoration('Description detaillee'),
            style: const TextStyle(fontSize: 13),
            maxLines: 4,
            onChanged: notifier.updateDescriptionLongue,
          ),
          const SizedBox(height: 14),

          // Public cible
          _sectionLabel('Public cible'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kPublicCible.map((p) {
              final selected = state.publicCible == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
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
          const SizedBox(height: 14),

          // Niveau
          _sectionLabel('Niveau'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kNiveaux.map((n) {
              final selected = state.niveau == n;
              return ChoiceChip(
                label: Text(n, style: const TextStyle(fontSize: 11)),
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
          const SizedBox(height: 16),

          // Organisateur
          _subsectionLabel('Organisateur'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kOrganisateurTypes.map((t) {
              final selected = state.organisateurType == t;
              return ChoiceChip(
                label: Text(t, style: const TextStyle(fontSize: 11)),
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
            decoration: _inputDecoration('Nom de l\'organisateur'),
            style: const TextStyle(fontSize: 13),
            onChanged: notifier.updateOrganisateurNom,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _orgEmailController,
            decoration: _inputDecoration('Email'),
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.updateOrganisateurEmail,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _orgTelController,
                  decoration: _inputDecoration('Telephone'),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.updateOrganisateurTelephone,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _orgSiteController,
                  decoration: _inputDecoration('Site web'),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.url,
                  onChanged: notifier.updateOrganisateurSite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Participants
          _subsectionLabel('Participants'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minController,
                  decoration: _inputDecoration('Min'),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: notifier.updateParticipantsMin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _maxController,
                  decoration: _inputDecoration('Max'),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: notifier.updateParticipantsMax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionLabel('Type d\'inscription'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kInscriptionTypes.map((t) {
              final selected = state.inscriptionType == t;
              return ChoiceChip(
                label: Text(t, style: const TextStyle(fontSize: 11)),
                selected: selected,
                selectedColor: _primaryColor.withValues(alpha: 0.15),
                checkmarkColor: _primaryColor,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => notifier.updateInscriptionType(t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkColor),
    );
  }

  static Widget _subsectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkColor),
    );
  }

  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
    );
  }
}
