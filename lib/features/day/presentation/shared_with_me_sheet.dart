import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/state/shared_events_provider.dart';

/// Bottom sheet affichant les events partages avec l'utilisateur.
class SharedWithMeSheet extends ConsumerWidget {
  const SharedWithMeSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SharedWithMeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedAsync = ref.watch(sharedWithMeProvider);

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
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          _buildHeader(sharedAsync),

          const Divider(height: 1),

          // Content
          Flexible(
            child: sharedAsync.when(
              data: (events) {
                if (events.isEmpty) return _buildEmpty();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _SharedEventCard(event: events[index]),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF6C5CE7),
                        strokeWidth: 2.5,
                        backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chargement...',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 32, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Impossible de charger',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(sharedWithMeProvider),
                      child: Text(
                        'Reessayer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<UserEvent>> sharedAsync) {
    final count = sharedAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partages avec moi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count event${count > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 34,
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Rien pour le moment',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quand un ami partagera un event\navec toi, il apparaitra ici',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SharedEventCard extends StatelessWidget {
  final UserEvent event;
  const _SharedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date.isNotEmpty
        ? DateFormat('dd/MM', 'fr_FR').format(DateTime.parse(event.date))
        : '';

    return GestureDetector(
      onTap: () => EventFullscreenPopup.show(
        context,
        event.toEvent(),
        'assets/images/pochette_concert.png',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo ou placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                child: event.photoUrl != null
                    ? Image.network(event.photoUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.event, color: Color(0xFF6C5CE7), size: 24),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (dateStr.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (event.lieuNom.isNotEmpty) ...[
                        Icon(Icons.place, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF6C5CE7), size: 20),
          ],
        ),
      ),
    );
  }
}
