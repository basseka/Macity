import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  static const _labels = [
    'Essentiel',
    'Quand & Ou',
    'Tarifs',
    'Details',
    'Extras',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i == currentStep;
            final isDone = i < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 3 : 0),
                decoration: BoxDecoration(
                  color: isDone
                      ? _primaryColor
                      : isActive
                          ? _primaryColor.withValues(alpha: 0.6)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Etape ${currentStep + 1}/$totalSteps — ${_labels[currentStep]}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
