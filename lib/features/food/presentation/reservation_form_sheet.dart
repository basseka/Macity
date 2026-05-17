import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/food/data/restaurant_reservation_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

/// Bottom sheet pour creer une demande de reservation. Affiche un form
/// minimal (date / heure / nb personnes / commentaire), envoie via l'edge
/// function submit-reservation. Le resto repond ensuite par email.
class ReservationFormSheet extends ConsumerStatefulWidget {
  final int venueId;
  final String venueName;

  const ReservationFormSheet({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int venueId,
    required String venueName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => ReservationFormSheet(
        venueId: venueId,
        venueName: venueName,
      ),
    );
  }

  @override
  ConsumerState<ReservationFormSheet> createState() =>
      _ReservationFormSheetState();
}

class _ReservationFormSheetState extends ConsumerState<ReservationFormSheet> {
  static const _primary = Color(0xFF7B2D8E);
  static const _dark = Color(0xFF4A1259);

  DateTime? _date;
  TimeOfDay? _heure;
  int _nbPersonnes = 2;
  final _commentaireCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var selected = _date ?? today;
    if (selected.isBefore(today)) selected = today;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      child: Text('Annuler', style: TextStyle(color: AppColors.textFaint)),
                    ),
                    Text('Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _date = selected);
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(fontSize: 20, color: AppColors.text),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumDate: today,
                    maximumDate: today.add(const Duration(days: 90)),
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickHeure() async {
    final initial = _heure ?? const TimeOfDay(hour: 20, minute: 0);
    final now = DateTime.now();
    var selected = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      child: Text('Annuler', style: TextStyle(color: AppColors.textFaint)),
                    ),
                    Text('Heure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _heure = TimeOfDay(hour: selected.hour, minute: selected.minute));
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(fontSize: 22, color: AppColors.text),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selected,
                    use24hFormat: true,
                    minuteInterval: 15,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_date == null) {
      setState(() => _error = 'Choisis une date');
      return;
    }
    if (_heure == null) {
      setState(() => _error = 'Choisis une heure');
      return;
    }
    final prenom = ref.read(userPrenomProvider).valueOrNull ?? '';
    if (prenom.isEmpty) {
      setState(() => _error = 'Termine ton inscription (prénom requis)');
      return;
    }

    setState(() => _submitting = true);
    try {
      final heureStr =
          '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}';
      await RestaurantReservationService().submit(
        venueId: widget.venueId,
        userPrenom: prenom,
        userTelephone: _telCtrl.text.trim(),
        date: _date!,
        heure: heureStr,
        nbPersonnes: _nbPersonnes,
        commentaire: _commentaireCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF22C55E),
          content: Text('Demande envoyée. Tu seras notifié dès la réponse.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: _primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réserver',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                        Text(
                          widget.venueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: _date != null
                                ? DateFormat('d MMM yyyy', 'fr_FR').format(_date!)
                                : null,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.access_time,
                            label: 'Heure',
                            value: _heure != null
                                ? '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}'
                                : null,
                            onTap: _pickHeure,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Nombre de personnes'),
                    const SizedBox(height: 6),
                    _NbPersonnesStepper(
                      value: _nbPersonnes,
                      onChanged: (v) => setState(() => _nbPersonnes = v),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _input('Téléphone (facultatif)'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentaireCtrl,
                      decoration: _input('Commentaire (allergies, occasion...)'),
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: Text(
                      _submitting ? 'Envoi...' : 'Envoyer la demande',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark),
      );

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        isDense: true,
      );
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  static const _primary = Color(0xFF7B2D8E);

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue ? _primary.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primary.withValues(alpha: 0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hasValue ? _primary : Colors.grey.shade600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primary : Colors.grey.shade600,
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

class _NbPersonnesStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _NbPersonnesStepper({required this.value, required this.onChanged});

  static const _primary = Color(0xFF7B2D8E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, color: _primary),
            iconSize: 22,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value personne${value > 1 ? "s" : ""}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline, color: _primary),
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}
