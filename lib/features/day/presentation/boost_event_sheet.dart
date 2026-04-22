import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Bottom sheet pour booster un event (changer sa priorite).
/// Affiche un calendrier de disponibilite avant de confirmer.
class BoostEventSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String eventDate;
  final String currentPriority;

  const BoostEventSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.currentPriority,
  });

  static Future<String?> show(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required String eventDate,
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
        eventDate: eventDate,
        currentPriority: currentPriority,
      ),
    );
  }

  @override
  State<BoostEventSheet> createState() => _BoostEventSheetState();
}

class _BoostEventSheetState extends State<BoostEventSheet> {
  bool _loading = false;
  bool _boosting = false;
  String? _selectedPriority;
  Map<String, _DaySlot> _availability = {};
  String? _error;

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
  ];

  @override
  void initState() {
    super.initState();
    // Charge la dispo P1 par defaut
    _loadAvailability('P1');
  }

  Dio get _dio {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<void> _loadAvailability(String priority) async {
    setState(() {
      _loading = true;
      _selectedPriority = priority;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(now);
      final endDate = DateFormat('yyyy-MM-dd').format(
        now.add(const Duration(days: 30)),
      );

      final res = await _dio.post(
        'rpc/boost_availability',
        data: {
          'p_priority': priority,
          'p_start_date': startDate,
          'p_end_date': endDate,
        },
      );

      final data = res.data as List;
      final map = <String, _DaySlot>{};
      for (final row in data) {
        final date = row['boost_date'] as String;
        final reserved = (row['reserved_count'] as num).toInt();
        final max = (row['max_slots'] as num).toInt();
        map[date] = _DaySlot(reserved: reserved, maxSlots: max);
      }

      if (mounted) {
        setState(() {
          _availability = map;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de charger les disponibilites';
        });
      }
    }
  }

  bool _isDateAvailable(String dateStr) {
    final slot = _availability[dateStr];
    if (slot == null) return true; // pas de data = probablement dispo
    return slot.reserved < slot.maxSlots;
  }

  Future<void> _boost() async {
    final priority = _selectedPriority;
    if (priority == null) return;

    // Verifie la dispo pour la date de l'event
    if (!_isDateAvailable(widget.eventDate)) {
      setState(() => _error = 'Plus de place $priority pour cette date');
      return;
    }

    setState(() {
      _boosting = true;
      _error = null;
    });

    try {
      // 1. Creer la reservation
      await _dio.post(
        'boost_reservations',
        data: {
          'event_id': widget.eventId,
          'user_id': widget.eventId, // device UUID serait mieux mais on utilise event_id
          'priority': priority,
          'boost_date': widget.eventDate,
          'status': 'confirmed',
        },
        options: Options(
          headers: {'Prefer': 'return=minimal'},
        ),
      );

      // 2. Mettre a jour la priorite de l'event
      await _dio.patch(
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
      setState(() {
        _boosting = false;
        _error = 'Erreur lors du boost. Reessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  size: 32,
                  color: Color(0xFFE91E8C),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booster votre event',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textFaint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (widget.currentPriority != 'P4') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
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

          const SizedBox(height: 16),

          // Tabs P1 / P2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _boostOptions.map((opt) {
                final isActive = _selectedPriority == opt.priority;
                return Expanded(
                  child: GestureDetector(
                    onTap: _boosting
                        ? null
                        : () => _loadAvailability(opt.priority),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? opt.color.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? opt.color : AppColors.lineStrong,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(opt.icon, size: 20, color: opt.color),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? opt.color
                                  : AppColors.textDim,
                            ),
                          ),
                          Text(
                            '${opt.price}\u20AC/jour',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Calendrier de disponibilite
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 14,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  'Disponibilite des 30 prochains jours',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: _AvailabilityCalendar(
                availability: _availability,
                eventDate: widget.eventDate,
                accentColor: _boostOptions
                    .firstWhere((o) => o.priority == _selectedPriority,
                        orElse: () => _boostOptions.first)
                    .color,
              ),
            ),

          // Legende
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                _LegendDot(
                  color: Colors.green.shade400,
                  label: 'Dispo',
                ),
                const SizedBox(width: 14),
                _LegendDot(
                  color: Colors.orange.shade400,
                  label: 'Presque plein',
                ),
                const SizedBox(width: 14),
                _LegendDot(
                  color: Colors.red.shade400,
                  label: 'Complet',
                ),
              ],
            ),
          ),

          // Erreur
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          // CTA Booster
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _boosting ||
                        _selectedPriority == null ||
                        !_isDateAvailable(widget.eventDate)
                    ? null
                    : _boost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _boostOptions
                      .firstWhere(
                        (o) => o.priority == _selectedPriority,
                        orElse: () => _boostOptions.first,
                      )
                      .color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.lineStrong,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _boosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch, size: 16),
                label: Text(
                  _boosting
                      ? 'Boost en cours...'
                      : !_isDateAvailable(widget.eventDate)
                          ? 'Complet pour cette date'
                          : 'Booster maintenant',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // Cancel
          TextButton(
            onPressed: _boosting ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Pas maintenant',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textFaint,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Calendrier de disponibilite
// ───────────────────────────────────────────

class _AvailabilityCalendar extends StatelessWidget {
  final Map<String, _DaySlot> availability;
  final String eventDate;
  final Color accentColor;

  const _AvailabilityCalendar({
    required this.availability,
    required this.eventDate,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      30,
      (i) => now.add(Duration(days: i)),
    );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final slot = availability[dateStr];
        final reserved = slot?.reserved ?? 0;
        final max = slot?.maxSlots ?? 5;
        final ratio = max > 0 ? reserved / max : 0.0;
        final isEventDate = dateStr == eventDate;

        Color dotColor;
        if (ratio >= 1.0) {
          dotColor = Colors.red.shade400;
        } else if (ratio >= 0.6) {
          dotColor = Colors.orange.shade400;
        } else {
          dotColor = Colors.green.shade400;
        }

        return Container(
          decoration: BoxDecoration(
            color: isEventDate
                ? accentColor.withValues(alpha: 0.12)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: isEventDate
                ? Border.all(color: accentColor, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isEventDate ? FontWeight.w800 : FontWeight.w600,
                  color: isEventDate
                      ? accentColor
                      : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (isEventDate) ...[
                const SizedBox(height: 1),
                Text(
                  '${max - reserved} place${max - reserved > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────
// Helpers
// ───────────────────────────────────────────

class _DaySlot {
  final int reserved;
  final int maxSlots;
  const _DaySlot({required this.reserved, required this.maxSlots});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: AppColors.textDim,
          ),
        ),
      ],
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
