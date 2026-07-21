import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/state/story_outbox_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_paged_sheet.dart';
import 'package:pulz_app/features/rewards/presentation/city_miles_card.dart';

/// Provider qui recupere uniquement les events du user courant.
final myPublicationsProvider = FutureProvider<List<UserEvent>>((ref) {
  return UserEventSupabaseService().fetchMyEvents();
});

/// Provider qui recupere les stories (reported_events) du user courant,
/// tous statuts (expirees incluses), gardees 1 mois.
/// autoDispose : refetch a chaque ouverture de la sheet (stories fraiches).
final myStoriesProvider = FutureProvider.autoDispose<List<ReportedEvent>>((ref) {
  return ReportedEventsService().fetchMyStories();
});

class MyPublicationsSheet extends ConsumerWidget {
  const MyPublicationsSheet({super.key, this.fromAccountMenu = false});

  final bool fromAccountMenu;

  static void show(BuildContext context, {bool fromAccountMenu = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MyPublicationsSheet(fromAccountMenu: fromAccountMenu),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myPublicationsProvider);
    final storiesAsync = ref.watch(myStoriesProvider);

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
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (fromAccountMenu)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 26),
                    color: AppColors.textDim,
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lineStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          _buildHeader(
            (eventsAsync.valueOrNull?.length ?? 0) +
                (storiesAsync.valueOrNull?.length ?? 0),
          ),
          const CityMilesCard(),
          _buildPendingBanner(context, ref),
          const Divider(height: 1),
          Flexible(
            child: _buildBody(context, ref, eventsAsync, storiesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<UserEvent>> eventsAsync,
    AsyncValue<List<ReportedEvent>> storiesAsync,
  ) {
    // Loader tant que les deux sources chargent (aucune donnee encore).
    if (eventsAsync.isLoading &&
        storiesAsync.isLoading &&
        !eventsAsync.hasValue &&
        !storiesAsync.hasValue) {
      return Padding(
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
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textFaint),
            ),
          ],
        ),
      );
    }

    final events = eventsAsync.valueOrNull ?? const [];
    final stories = storiesAsync.valueOrNull ?? const [];

    if (events.isEmpty && stories.isEmpty) return _buildEmpty();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Section evenements ──
        if (events.isNotEmpty) ...[
          _sectionHeader(
            'Mes evenements',
            events.length,
            Icons.calendar_today_rounded,
            const Color(0xFF00B894),
          ),
          const SizedBox(height: 10),
          for (final event in events) ...[
            _PublicationCard(
              event: event,
              onBoost: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEventPage(eventToEdit: event, initialStep: 2),
                  ),
                );
              },
              onEdit: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEventPage(eventToEdit: event),
                  ),
                );
              },
              onDelete: () => _confirmDelete(context, ref, event),
            ),
            const SizedBox(height: 10),
          ],
        ],

        // ── Section stories ──
        if (stories.isNotEmpty) ...[
          if (events.isNotEmpty) const SizedBox(height: 12),
          _sectionHeader(
            'Mes stories',
            stories.length,
            Icons.auto_awesome_rounded,
            const Color(0xFFE91E8C),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'Conservees un temps limite. Supprimables a tout moment.',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textFaint),
            ),
          ),
          for (final story in stories) ...[
            _StoryCard(
              story: story,
              onOpen: () => ReportedEventsPagedSheet.open(
                context,
                events: [story],
                initialIndex: 0,
              ),
              onDelete: () => _confirmDeleteStory(context, ref, story),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
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
                    '$count publication${count > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textFaint),
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
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tes evenements crees apparaitront ici',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }

  /// Banniere « stories en attente d'envoi » (buffer offline). Masquee si la
  /// file est vide. Bouton pour forcer une tentative d'envoi immediate.
  Widget _buildPendingBanner(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(storyOutboxProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final n = pending.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x142D6A8E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x332D6A8E)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined,
                size: 18, color: Color(0xFF2D6A8E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n == 1
                    ? '1 story en attente de reseau'
                    : '$n stories en attente de reseau',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(storyOutboxProvider.notifier).flushNow(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A8E),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Envoyer',
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
              style: GoogleFonts.poppins(color: AppColors.textFaint),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok =
                  await ref.read(userEventsProvider.notifier).removeEvent(event.id);
              ref.invalidate(myPublicationsProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Publication supprimee' : 'Suppression impossible, reessaye',
                  ),
                ),
              );
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

  void _confirmDeleteStory(BuildContext context, WidgetRef ref, ReportedEvent story) {
    final title = story.generated?.title ??
        (story.rawTitle.isNotEmpty ? story.rawTitle : 'cette story');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer la story',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Supprimer "$title" ? Cette action est definitive.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: AppColors.textFaint),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              bool ok = false;
              try {
                ok = await ReportedEventsService().deleteMyStory(story.id);
              } catch (_) {
                ok = false;
              }
              ref.invalidate(myStoriesProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Story supprimee' : 'Suppression impossible, reessaye',
                  ),
                ),
              );
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
  final VoidCallback onBoost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PublicationCard({required this.event, required this.onBoost, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date.isNotEmpty
        ? DateFormat('EEE d MMM', 'fr_FR').format(DateTime.parse(event.date))
        : '';

    return GestureDetector(
      onTap: () => EventFullscreenPopup.show(
        context,
        event.toEvent(),
        'assets/images/pochette_concert.webp',
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
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
                          Icon(Icons.calendar_today, size: 10, color: AppColors.textFaint),
                          const SizedBox(width: 3),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textFaint),
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

            // Boost
            GestureDetector(
              onTap: onBoost,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6EB4).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_outlined, size: 15, color: Color(0xFFE91E8C)),
              ),
            ),
            const SizedBox(width: 6),

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

/// Carte d'une story (reported_event) dans « Mes publications ».
class _StoryCard extends StatelessWidget {
  final ReportedEvent story;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _StoryCard({required this.story, required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = story.generated?.title ??
        (story.rawTitle.isNotEmpty ? story.rawTitle : story.category);
    final dateStr = DateFormat('d MMM • HH:mm', 'fr_FR').format(story.createdAt.toLocal());
    final expired = story.expiresAt.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 52, height: 52, child: _buildThumb()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 10, color: AppColors.textFaint),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textFaint),
                        ),
                        const SizedBox(width: 6),
                        _statusBadge(expired),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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

  Widget _statusBadge(bool expired) {
    final generating = story.isGenerating;
    final label = generating ? 'En cours' : (expired ? 'Expiree' : 'En ligne');
    final color = generating
        ? const Color(0xFF7B2D8E)
        : (expired ? AppColors.textFaint : const Color(0xFF00B894));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildThumb() {
    final photo = story.coverPhoto;
    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) => _thumbPlaceholder(),
        errorWidget: (_, __, ___) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFE91E8C).withValues(alpha: 0.08),
      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE91E8C), size: 22),
    );
  }
}
