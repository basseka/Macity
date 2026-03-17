import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';

class StepPricing extends ConsumerStatefulWidget {
  const StepPricing({super.key});

  @override
  ConsumerState<StepPricing> createState() => _StepPricingState();
}

class _StepPricingState extends ConsumerState<StepPricing> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);
  late final TextEditingController _lienController;
  late final TextEditingController _prixController;
  late final TextEditingController _prixReduitController;
  late final TextEditingController _prixGroupeController;
  late final TextEditingController _prixEarlyBirdController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _lienController = TextEditingController();
    _prixController = TextEditingController();
    _prixReduitController = TextEditingController();
    _prixGroupeController = TextEditingController();
    _prixEarlyBirdController = TextEditingController();
  }

  @override
  void dispose() {
    _lienController.dispose();
    _prixController.dispose();
    _prixReduitController.dispose();
    _prixGroupeController.dispose();
    _prixEarlyBirdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    if (!_initialized) {
      _initialized = true;
      _lienController.text = state.lienBilletterie;
      _prixController.text = state.prix;
      _prixReduitController.text = state.prixReduit;
      _prixGroupeController.text = state.prixGroupe;
      _prixEarlyBirdController.text = state.prixEarlyBird;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarifs & Billetterie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkColor),
          ),
          const SizedBox(height: 2),
          Text(
            'Tarification et lien d\'achat',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),

          // Toggle gratuit/payant
          SwitchListTile(
            value: state.estGratuit,
            onChanged: notifier.updateEstGratuit,
            title: const Text(
              'Evenement gratuit',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            activeTrackColor: _primaryColor.withValues(alpha: 0.4),
            thumbColor: const WidgetStatePropertyAll(_primaryColor),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 10),

          // Prix (si payant)
          if (!state.estGratuit) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixController,
                    decoration: _inputDecoration('Prix (EUR)'),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updatePrix,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _prixReduitController,
                    decoration: _inputDecoration('Tarif reduit'),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updatePrixReduit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixGroupeController,
                    decoration: _inputDecoration('Tarif groupe'),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updatePrixGroupe,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _prixEarlyBirdController,
                    decoration: _inputDecoration('Early bird'),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updatePrixEarlyBird,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Lien billetterie
          TextFormField(
            controller: _lienController,
            decoration: _inputDecoration('Lien billetterie ou site (optionnel)'),
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.url,
            onChanged: notifier.updateLienBilletterie,
          ),
          const SizedBox(height: 4),
          Text(
            'Doit commencer par http:// ou https://',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
