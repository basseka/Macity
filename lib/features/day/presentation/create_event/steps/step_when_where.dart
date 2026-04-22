import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';

class StepWhenWhere extends ConsumerStatefulWidget {
  const StepWhenWhere({super.key});

  @override
  ConsumerState<StepWhenWhere> createState() => _StepWhenWhereState();
}

class _StepWhenWhereState extends ConsumerState<StepWhenWhere> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);
  late final TextEditingController _adresseController;
  late final TextEditingController _lieuNomController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _adresseController = TextEditingController();
    _lieuNomController = TextEditingController();
  }

  @override
  void dispose() {
    _adresseController.dispose();
    _lieuNomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);
    final city = ref.watch(selectedCityProvider);

    // Initialize ville from city provider
    if (!_initialized) {
      _initialized = true;
      if (state.ville.isEmpty) {
        Future.microtask(() => notifier.updateVille(city));
      }
      _adresseController.text = state.lieuAdresse;
      _lieuNomController.text = state.lieuNom ?? '';
    }

    // Resynchronise les controllers quand le state a ete pre-rempli
    // (loadEvent ou prefillFromScan) apres la 1ere construction.
    ref.listen<CreateEventState>(createEventProvider, (prev, next) {
      if (prev != null && prev.prefillRevision != next.prefillRevision) {
        _adresseController.text = next.lieuAdresse;
        _lieuNomController.text = next.lieuNom ?? '';
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quand & Ou',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkColor),
          ),
          const SizedBox(height: 2),
          Text(
            'Date, heure et lieu de l\'evenement',
            style: TextStyle(fontSize: 12, color: AppColors.textFaint),
          ),
          const SizedBox(height: 14),

          // Date debut + Heure debut
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Date debut *',
                  value: state.dateDebut,
                  onPicked: notifier.updateDateDebut,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimePickerField(
                  label: 'Heure debut *',
                  value: state.heureDebut,
                  onPicked: notifier.updateHeureDebut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date fin + Heure fin (optionnel)
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Date fin',
                  value: state.dateFin,
                  onPicked: notifier.updateDateFin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimePickerField(
                  label: 'Heure fin',
                  value: state.heureFin,
                  onPicked: notifier.updateHeureFin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recurrence
          _sectionLabel('Recurrence'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Quotidien', 'Hebdomadaire', 'Mensuel'].map((r) {
              final selected = state.recurrenceType == r.toLowerCase();
              return FilterChip(
                label: Text(r, style: const TextStyle(fontSize: 11)),
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
          const SizedBox(height: 14),

          // Type de lieu
          _sectionLabel('Type de lieu'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kLieuTypes.map((lt) {
              final selected = state.lieuType == lt;
              return ChoiceChip(
                label: Text(lt, style: const TextStyle(fontSize: 11)),
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
          const SizedBox(height: 14),

          // Lieu
          TextFormField(
            controller: _lieuNomController,
            decoration: _inputDecoration('Nom du lieu'),
            style: const TextStyle(fontSize: 13),
            onChanged: notifier.updateLieuNom,
          ),
          const SizedBox(height: 10),

          // Adresse
          TextFormField(
            controller: _adresseController,
            decoration: _inputDecoration('Adresse'),
            style: const TextStyle(fontSize: 13),
            onChanged: notifier.updateLieuAdresse,
          ),
          const SizedBox(height: 10),

          // Ville (pre-remplie)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city, size: 16, color: _primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        state.ville.isNotEmpty ? state.ville : city,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _darkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    state.pays,
                    style: TextStyle(fontSize: 13, color: AppColors.textDim),
                  ),
                ),
              ),
            ],
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

  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: AppColors.textFaint),
      filled: true,
      fillColor: Colors.grey.shade50,
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  void _showPicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var selected = value ?? today;
    // Ensure selected is not before minimum
    if (selected.isBefore(today)) selected = today;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          height: 320 + bottomPadding,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler', style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                    ),
                    const Text('Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPicked(selected);
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.magenta,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 20,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumDate: today,
                    maximumDate: today.add(const Duration(days: 365)),
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
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
            Icon(Icons.calendar_today, size: 16, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue ? DateFormat('d MMM yyyy', 'fr_FR').format(value!) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  void _showPicker(BuildContext context) {
    final now = DateTime.now();
    // Round to nearest 5-minute interval
    final defaultMinute = (value?.minute ?? 0);
    final roundedMinute = (defaultMinute / 5).round() * 5;
    var selected = value != null
        ? DateTime(now.year, now.month, now.day, value!.hour, roundedMinute.clamp(0, 55))
        : DateTime(now.year, now.month, now.day, 20, 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          height: 320 + bottomPadding,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler', style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                    ),
                    const Text('Heure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPicked(TimeOfDay(hour: selected.hour, minute: selected.minute));
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.magenta,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 22,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selected,
                    use24hFormat: true,
                    minuteInterval: 5,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
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
            Icon(Icons.access_time, size: 16, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}' : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
