import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';
import 'package:pulz_app/features/day/presentation/create_event/steps/step_details.dart';
import 'package:pulz_app/features/day/presentation/create_event/steps/step_essentials.dart';
import 'package:pulz_app/features/day/presentation/create_event/steps/step_extras.dart';
import 'package:pulz_app/features/day/presentation/create_event/steps/step_pricing.dart';
import 'package:pulz_app/features/day/presentation/create_event/steps/step_when_where.dart';
import 'package:pulz_app/features/day/presentation/create_event/widgets/step_indicator.dart';
import 'package:pulz_app/core/services/stripe_service.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  final String? initialPhotoPath;

  const CreateEventPage({super.key, this.initialPhotoPath});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  late final PageController _pageController;
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.initialPhotoPath != null) {
      Future.microtask(() {
        ref.read(createEventProvider.notifier).updatePhotoPath(widget.initialPhotoPath!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    ref.listen<CreateEventState>(createEventProvider, (prev, next) {
      if (prev != null && prev.currentStep != next.currentStep) {
        _animateToPage(next.currentStep);
      }
    });

    return Stack(
      children: [
      Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _primaryDarkColor),
          onPressed: () => _confirmExit(context),
        ),
        title: const Text(
          'Creer un evenement',
          style: TextStyle(
            color: _primaryDarkColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: StepIndicator(
                currentStep: state.currentStep,
                totalSteps: CreateEventState.totalSteps,
              ),
            ),

            // Error message
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StepEssentials(),
                  StepWhenWhere(),
                  StepPricing(),
                  StepDetails(),
                  StepExtras(),
                ],
              ),
            ),

            // Bottom navigation
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
              children: [
                // Precedent
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryDarkColor,
                        side: const BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Precedent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: 10),

                // Passer (etapes 4-5)
                if (state.isCurrentStepSkippable &&
                    state.currentStep < CreateEventState.totalSteps - 1) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.skipStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Passer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Suivant / Publier
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _onNextOrSubmit(state, notifier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLastStep(state) ? 'Publier' : 'Suivant',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    ),
    // Overlay de progression pendant l'upload
    if (state.isSubmitting)
      Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFE91E8C),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.isVideo ? 'Publication de la video...' : 'Publication en cours...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              if (state.isVideo)
                const _UploadSteps()
              else
                Text(
                  'Presque termine',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
    );
  }

  bool _isLastStep(CreateEventState state) {
    return state.currentStep == CreateEventState.totalSteps - 1;
  }

  Future<void> _onNextOrSubmit(
    CreateEventState state,
    CreateEventNotifier notifier,
  ) async {
    if (_isLastStep(state)) {
      final success = await notifier.submit();
      if (success && mounted) {
        final priority = state.priority;
        if ((priority == 'P1' || priority == 'P2') && notifier.lastCreatedEventId != null) {
          // Boost payant sélectionné → paiement Stripe
          final userId = await UserIdentityService.getUserId();
          final sortedDates = state.boostDates.toList()..sort();
          final startDate = sortedDates.isNotEmpty ? sortedDates.first : DateTime.now();
          StripeService.checkout(
            eventId: notifier.lastCreatedEventId!,
            eventTitle: state.titre,
            priority: priority,
            userId: userId,
            days: state.boostDates.length.clamp(1, 30),
            startDate: startDate,
          );
        }
        _showSuccessAndPop();
      }
    } else {
      notifier.nextStep();
    }
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primaryColor, Color(0xFFE91E8C)],
                ),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Evenement ajoute\navec succes !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primaryDarkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Il sera visible dans la rubrique correspondante.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final state = ref.read(createEventProvider);
    // If nothing filled, just pop
    if (state.titre.isEmpty && state.categorie == null && state.photoPath == null) {
      Navigator.of(context).pop();
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter ?'),
        content: const Text('Les informations saisies seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Timeline animee pour l'upload video.
class _UploadSteps extends StatefulWidget {
  const _UploadSteps();

  @override
  State<_UploadSteps> createState() => _UploadStepsState();
}

class _UploadStepsState extends State<_UploadSteps> {
  int _step = 0;
  static const _steps = [
    'Compression de la video...',
    'Upload en cours...',
    'Finalisation...',
  ];

  @override
  void initState() {
    super.initState();
    _advanceSteps();
  }

  void _advanceSteps() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _step = 1);
    await Future.delayed(const Duration(seconds: 15));
    if (mounted) setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i < _step
                      ? Icons.check_circle
                      : i == _step
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  size: 14,
                  color: i <= _step ? const Color(0xFFE91E8C) : Colors.white24,
                ),
                const SizedBox(width: 8),
                Text(
                  _steps[i],
                  style: TextStyle(
                    color: i <= _step ? Colors.white : Colors.white24,
                    fontSize: 11,
                    fontWeight: i == _step ? FontWeight.w600 : FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
