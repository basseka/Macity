import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';

class DateRangeChipBar extends ConsumerWidget {
  const DateRangeChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dateRangeFilterProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    final chips = <_ChipData>[
      const _ChipData('Tout', DateRangePreset.all),
      const _ChipData('7 jours', DateRangePreset.days7),
      const _ChipData('30 jours', DateRangePreset.days30),
      _ChipData(
        filter.preset == DateRangePreset.custom &&
                filter.customStart != null &&
                filter.customEnd != null
            ? 'Du ${DateFormat('dd/MM').format(filter.customStart!)} au ${DateFormat('dd/MM').format(filter.customEnd!)}'
            : 'Date',
        DateRangePreset.custom,
      ),
    ];

    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: chips.map((chip) {
            final isSelected = filter.preset == chip.preset;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(chip.label),
                selected: isSelected,
                onSelected: (_) async {
                  if (chip.preset == DateRangePreset.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.copyWith(
                              headlineSmall: const TextStyle(fontSize: 16),
                              titleSmall: const TextStyle(fontSize: 11),
                              bodySmall: const TextStyle(fontSize: 11),
                            ),
                          ),
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(0.85),
                            ),
                            child: child!,
                          ),
                        );
                      },
                    );
                    if (picked != null) {
                      ref.read(dateRangeFilterProvider.notifier).state =
                          DateRangeFilter(
                        preset: DateRangePreset.custom,
                        customStart: picked.start,
                        customEnd: picked.end,
                      );
                    }
                  } else {
                    ref.read(dateRangeFilterProvider.notifier).state =
                        DateRangeFilter(preset: chip.preset);
                  }
                },
                selectedColor: modeTheme.chipBgColor,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected
                      ? modeTheme.chipTextColor
                      : Colors.grey.shade600,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
                side: BorderSide(
                  color: isSelected
                      ? modeTheme.chipStrokeColor
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final DateRangePreset preset;
  const _ChipData(this.label, this.preset);
}
