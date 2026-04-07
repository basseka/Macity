import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/state/boost_prices_provider.dart';
import 'package:pulz_app/features/day/state/boost_availability_provider.dart';
import 'package:intl/intl.dart';

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

          // Boost (en premier)
          Container(
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
                        'Booster votre event',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
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
                  'Augmentez la visibilite de votre event',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                ..._buildBoostOptions(ref, state, notifier),
                // Sélecteur de jours + total (visible si boost payant sélectionné)
                if (state.priority != 'P4' && state.priority != 'P3') ...[
                  const SizedBox(height: 12),
                  _buildDaysSelector(ref, state, notifier),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

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

  Widget _buildDaysSelector(WidgetRef ref, dynamic state, dynamic notifier) {
    final pricesAsync = ref.watch(boostPricesProvider);
    final selectedDates = state.boostDates as Set<DateTime>;
    final count = selectedDates.length;
    final priority = state.priority as String;
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
        final color = _boostColors[priority] ?? _primaryColor;

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
              // Titre + compteur
              Row(
                children: [
                  Expanded(
                    child: Text('Touchez les jours souhaites', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ),
                  if (count > 0)
                    GestureDetector(
                      onTap: () => notifier.clearBoostDates(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Effacer', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Calendrier
              availAsync.when(
                data: (avail) => _buildAvailabilityGrid(avail, selectedDates, color, notifier),
                loading: () => const SizedBox(height: 76, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const Text('Erreur chargement', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),

              // Légende
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _legendDot(Colors.green.shade400, 'Dispo'),
                  _legendDot(Colors.orange, 'Presque plein'),
                  _legendDot(Colors.red.shade400, 'Complet'),
                  _legendDot(color, 'Choisi'),
                ],
              ),

              // Résumé + total
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
                          '$count jour${count > 1 ? 's' : ''} x ${bp.amountCents ~/ 100}\u20AC',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        '$total\u20AC',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildAvailabilityGrid(List<DayAvailability> avail, Set<DateTime> selectedDates, Color color, dynamic notifier) {
    return SizedBox(
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
                color: isSelected ? color : (day.isFull ? Colors.grey.shade100 : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
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
                      color: isSelected ? Colors.white : (day.isFull ? Colors.grey.shade400 : const Color(0xFF1A1A2E)),
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'fr_FR').format(day.date),
                    style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : Colors.grey.shade500),
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
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

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

  List<Widget> _buildBoostOptions(WidgetRef ref, dynamic state, dynamic notifier) {
    final pricesAsync = ref.watch(boostPricesProvider);
    return pricesAsync.when(
      data: (prices) => prices.map((bp) {
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
      loading: () => [const Center(child: CircularProgressIndicator(strokeWidth: 2))],
      error: (_, __) => [const Text('Erreur chargement prix', style: TextStyle(fontSize: 11, color: Colors.red))],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, size: 18, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
