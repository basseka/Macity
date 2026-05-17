import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/create_private_event_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// Liste des soirees privees creees par ce device. Permet de re-partager le
/// lien+code et de supprimer un event.
class MyPrivateEventsScreen extends StatefulWidget {
  const MyPrivateEventsScreen({super.key});

  @override
  State<MyPrivateEventsScreen> createState() => _MyPrivateEventsScreenState();
}

class _MyPrivateEventsScreenState extends State<MyPrivateEventsScreen> {
  final _service = PrivateEventService();
  Future<List<PrivateEvent>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = () async {
        final uuid = await UserIdentityService.getUserId();
        return _service.listMyPrivateEvents(hostDeviceUuid: uuid);
      }();
    });
  }

  Future<void> _showGuests(PrivateEvent event) async {
    final hostUuid = await UserIdentityService.getUserId();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestsSheet(
        event: event,
        hostDeviceUuid: hostUuid,
      ),
    );
  }

  Future<void> _delete(PrivateEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Supprimer ce coffre ?',
          style: GoogleFonts.geist(color: AppColors.text),
        ),
        content: Text(
          'L\'event "${event.title}" ne sera plus accessible aux invites.',
          style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final uuid = await UserIdentityService.getUserId();
      await _service.deleteMyPrivateEvent(
        token: event.accessToken,
        hostDeviceUuid: uuid,
      );
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de la suppression')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'Mes events privés',
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      body: FutureBuilder<List<PrivateEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.magenta),
            );
          }
          final events = snap.data ?? [];
          if (events.isEmpty) return _empty();
          return RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EventTile(
                event: events[i],
                onShare: () => Share.share(
                  buildPrivateEventShareText(events[i]),
                ),
                onDelete: () => _delete(events[i]),
                onShowGuests: () => _showGuests(events[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreatePrivateEventSheet.show(
          context,
          onCreated: _reload,
        ),
        backgroundColor: AppColors.magenta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.lock_outline),
        label: Text(
          'Nouvel event',
          style: GoogleFonts.geist(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 38,
                color: AppColors.magenta,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucun event privé',
              style: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cree un coffre secret et invite tes amis avec un lien+code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final PrivateEvent event;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onShowGuests;

  const _EventTile({
    required this.event,
    required this.onShare,
    required this.onDelete,
    required this.onShowGuests,
  });

  String _friendlyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE d MMM', 'fr_FR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photoUrl != null && event.photoUrl!.isNotEmpty;
    return InkWell(
      onTap: onShowGuests,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : photo + titre + date
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHi,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: event.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.geist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _friendlyDate(event.date) +
                                (event.heure.isNotEmpty
                                    ? ' · ${event.heure}'
                                    : ''),
                            style: GoogleFonts.geist(
                              fontSize: 11,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                      if (event.lieu.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.textFaint,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.lieu,
                                style: GoogleFonts.geist(
                                  fontSize: 11,
                                  color: AppColors.textDim,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _OpensBadge(
                  open: event.openCount,
                  max: event.maxOpens,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Code + actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.magenta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: AppColors.magenta.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.key,
                        size: 12,
                        color: AppColors.magenta,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.passcode,
                        style: GoogleFonts.geistMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.magenta,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: AppColors.magenta,
                  ),
                  tooltip: 'Partager',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFFF6B6B),
                  ),
                  tooltip: 'Supprimer',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: AppColors.surfaceHi,
        child: Icon(
          Icons.celebration,
          color: AppColors.textFaint,
          size: 22,
        ),
      );
}

class _OpensBadge extends StatelessWidget {
  final int open;
  final int max;

  const _OpensBadge({required this.open, required this.max});

  @override
  Widget build(BuildContext context) {
    final saturated = open >= max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: saturated
            ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
            : AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$open/$max',
        style: GoogleFonts.geistMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: saturated ? const Color(0xFFFF6B6B) : AppColors.textDim,
        ),
      ),
    );
  }
}

/// Sheet liste des invites ayant accepte. Charge a l'ouverture via la RPC
/// host_list_event_rsvps (filtre serveur sur host_device_uuid).
class _GuestsSheet extends StatefulWidget {
  final PrivateEvent event;
  final String hostDeviceUuid;

  const _GuestsSheet({required this.event, required this.hostDeviceUuid});

  @override
  State<_GuestsSheet> createState() => _GuestsSheetState();
}

class _GuestsSheetState extends State<_GuestsSheet> {
  final _service = PrivateEventService();
  Future<List<PrivateEventRsvp>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.hostListEventRsvps(
      token: widget.event.accessToken,
      hostDeviceUuid: widget.hostDeviceUuid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 20,
                    color: AppColors.magenta,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invites — ${widget.event.title}',
                      style: GoogleFonts.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<PrivateEventRsvp>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.magenta,
                        ),
                      );
                    }
                    final rsvps = snap.data ?? [];
                    if (rsvps.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Personne pour l\'instant',
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              color: AppColors.textDim,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: rsvps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _GuestRow(rsvp: rsvps[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  final PrivateEventRsvp rsvp;
  const _GuestRow({required this.rsvp});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = rsvp.avatarUrl != null && rsvp.avatarUrl!.isNotEmpty;
    final initial = (rsvp.prenom ?? '?').isNotEmpty
        ? rsvp.prenom![0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: rsvp.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _initialFallback(initial),
                    placeholder: (_, __) => _initialFallback(initial),
                  )
                : _initialFallback(initial),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rsvp.prenom ?? 'Anonyme',
              style: GoogleFonts.geist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: AppColors.magenta),
        ],
      ),
    );
  }

  Widget _initialFallback(String initial) => Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.geist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}
