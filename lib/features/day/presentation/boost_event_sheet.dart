import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Bottom sheet pour booster un event (changer sa priorité).
class BoostEventSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String currentPriority;

  const BoostEventSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.currentPriority,
  });

  static Future<String?> show(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required String currentPriority,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoostEventSheet(
        eventId: eventId,
        eventTitle: eventTitle,
        currentPriority: currentPriority,
      ),
    );
  }

  @override
  State<BoostEventSheet> createState() => _BoostEventSheetState();
}

class _BoostEventSheetState extends State<BoostEventSheet> {
  bool _loading = false;
  String? _selectedPriority;

  static const _boostOptions = [
    _BoostOption(
      priority: 'P1',
      label: 'Boost Premium',
      price: '150',
      description: 'Visibilite maximale, en tete de tous les feeds',
      color: Color(0xFFFF6B00),
      icon: Icons.rocket_launch,
    ),
    _BoostOption(
      priority: 'P2',
      label: 'Boost Avance',
      price: '80',
      description: 'Mis en avant dans les feeds et les resultats',
      color: Color(0xFFE91E8C),
      icon: Icons.trending_up,
    ),
    _BoostOption(
      priority: 'P3',
      label: 'Boost Standard',
      price: '20',
      description: 'Meilleure visibilite dans votre categorie',
      color: Color(0xFF7B2D8E),
      icon: Icons.visibility,
    ),
  ];

  Future<void> _boost(String priority) async {
    setState(() {
      _loading = true;
      _selectedPriority = priority;
    });

    try {
      final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
      dio.interceptors.add(SupabaseInterceptor());

      await dio.patch(
        'user_events?id=eq.${widget.eventId}',
        data: {'priority': priority},
        options: Options(
          headers: {'Prefer': 'return=minimal'},
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(priority);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.rocket_launch, size: 36, color: Color(0xFFE91E8C)),
                const SizedBox(height: 10),
                Text(
                  'Booster votre event',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (widget.currentPriority != 'P4') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E8C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Boost actuel : ${widget.currentPriority}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE91E8C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options
          ...(_boostOptions.map((opt) => _buildOption(opt))),

          const SizedBox(height: 12),

          // Cancel
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Pas maintenant',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildOption(_BoostOption opt) {
    final isCurrentBoost = widget.currentPriority == opt.priority;
    final isSelected = _selectedPriority == opt.priority && _loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: _loading ? null : () => _boost(opt.priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentBoost ? opt.color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentBoost ? opt.color : Colors.grey.shade200,
              width: isCurrentBoost ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(opt.icon, color: opt.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          opt.label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        if (isCurrentBoost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: opt.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIF',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              isSelected
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: opt.color,
                      ),
                    )
                  : Column(
                      children: [
                        Text(
                          '${opt.price}\u20AC',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: opt.color,
                          ),
                        ),
                        Text(
                          '/jour',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoostOption {
  final String priority;
  final String label;
  final String price;
  final String description;
  final Color color;
  final IconData icon;

  const _BoostOption({
    required this.priority,
    required this.label,
    required this.price,
    required this.description,
    required this.color,
    required this.icon,
  });
}
