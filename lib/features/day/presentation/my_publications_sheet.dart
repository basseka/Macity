import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';

/// Provider qui recupere uniquement les events du user courant.
final myPublicationsProvider = FutureProvider<List<UserEvent>>((ref) {
  return UserEventSupabaseService().fetchMyEvents();
});

class MyPublicationsSheet extends ConsumerWidget {
  const MyPublicationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MyPublicationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myPublicationsProvider);

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
          _buildHeader(eventsAsync.valueOrNull?.length ?? 0),
          const Divider(height: 1),
          Flexible(
            child: eventsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF00B894),
                        strokeWidth: 2.5,
                        backgroundColor: const Color(0xFF00B894).withValues(alpha: 0.12),
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
              error: (_, __) => _buildEmpty(),
              data: (events) => events.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _PublicationCard(
                        event: event,
                        onEdit: () {
                          Navigator.pop(context);
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => CreateEventPage(eventToEdit: event),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, ref, event),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.article_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes publications',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count evenement${count > 1 ? 's' : ''}',
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
              color: const Color(0xFF00B894).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 34,
              color: const Color(0xFF00B894).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aucune publication',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tes evenements crees apparaitront ici',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, UserEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Supprimer "${event.titre}" ?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(userEventsProvider.notifier).removeEvent(event.id);
              ref.invalidate(myPublicationsProvider);
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  final UserEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PublicationCard({required this.event, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date.isNotEmpty
        ? DateFormat('EEE d MMM', 'fr_FR').format(DateTime.parse(event.date))
        : '';

    return GestureDetector(
      onTap: () => EventFullscreenPopup.show(
        context,
        event.toEvent(),
        'assets/images/pochette_concert.png',
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _buildPhoto(),
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.titre,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
                          Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (event.categorie.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.categorie,
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF00B894),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 4),

            // Edit
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2D8E).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF7B2D8E)),
              ),
            ),
            const SizedBox(width: 6),

            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final photo = event.photoUrl ?? event.photoPath;
    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF00B894).withValues(alpha: 0.08),
      child: const Icon(Icons.event, color: Color(0xFF00B894), size: 22),
    );
  }
}
