import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/day/data/shared_events_service.dart';
import 'package:pulz_app/features/day/state/shared_events_provider.dart';

/// Bottom sheet pour partager un event avec des contacts.
/// Utilise le Contact Picker systeme Android (pas de permission READ_CONTACTS).
class ShareEventSheet extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const ShareEventSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  static void show(BuildContext context, {required String eventId, required String eventTitle}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareEventSheet(eventId: eventId, eventTitle: eventTitle),
    );
  }

  @override
  ConsumerState<ShareEventSheet> createState() => _ShareEventSheetState();
}

class _ShareEventSheetState extends ConsumerState<ShareEventSheet> {
  static const _accent = Color(0xFF6C5CE7);
  static const _playStoreLink =
      'https://play.google.com/apps/internaltest/4700923192632434389';

  final List<PickedContact> _picked = [];
  bool _picking = false;
  bool _sending = false;
  bool _sent = false;

  List<PickedContact> get _pulzRecipients =>
      _picked.where((p) => p.isOnPulz).toList();
  List<PickedContact> get _nonPulzRecipients =>
      _picked.where((p) => !p.isOnPulz).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Flexible(
            child: _sent ? _buildSentState() : _buildBody(),
          ),
          if (!_sent) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_alt_rounded, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partager avec',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  widget.eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textFaint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_picked.isEmpty) return _buildEmptyState();
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _picked.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 72, color: Colors.grey.shade100),
      itemBuilder: (context, index) => _buildRecipientTile(_picked[index], index),
    );
  }

  Widget _buildRecipientTile(PickedContact c, int index) {
    final onPulz = c.isOnPulz;
    final initial = c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: onPulz
            ? _accent.withValues(alpha: 0.12)
            : AppColors.line,
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: onPulz ? _accent : AppColors.textDim,
          ),
        ),
      ),
      title: Text(
        c.displayName.isEmpty ? 'Contact sans nom' : c.displayName,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            onPulz ? Icons.check_circle : Icons.person_add_outlined,
            size: 13,
            color: onPulz ? const Color(0xFF4CAF50) : Colors.orange.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            onPulz ? 'Sur Pulz' : 'A inviter par SMS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: onPulz ? const Color(0xFF4CAF50) : Colors.orange.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 18, color: AppColors.textFaint),
        onPressed: () => setState(() => _picked.removeAt(index)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, size: 30, color: _accent),
          ),
          const SizedBox(height: 14),
          Text(
            'Ajoute des amis',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisis tes contacts pour partager cet event.\nDeja sur Pulz : envoi direct.\nPas encore : invitation SMS avec lien.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textFaint,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _picking || _sending ? null : _addContact,
                icon: _picking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      )
                    : const Icon(Icons.add_rounded, color: _accent, size: 20),
                label: Text(
                  _picking ? 'Recherche...' : 'Ajouter un contact',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_pulzRecipients.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _sharePulz,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Partager avec ${_pulzRecipients.length} ami${_pulzRecipients.length > 1 ? 's' : ''} sur Pulz',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            if (_nonPulzRecipients.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _inviteBySms,
                  icon: const Icon(Icons.sms_outlined, size: 18),
                  label: Text(
                    'Inviter ${_nonPulzRecipients.length} ami${_nonPulzRecipients.length > 1 ? 's' : ''} par SMS',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 36,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Partage envoye !',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tes amis verront cet event\ndans leur section "Partages avec moi"',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textFaint,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addContact() async {
    setState(() => _picking = true);
    try {
      final service = ref.read(sharedEventsServiceProvider);
      final result = await service.pickContactAndMatch();
      if (!mounted) return;
      if (result == null) return; // annule
      // Dedup : meme userId (Pulz) ou meme numero
      final alreadyAdded = _picked.any((p) {
        if (p.isOnPulz && result.isOnPulz) {
          return p.pulzUser!.userId == result.pulzUser!.userId;
        }
        return p.phone == result.phone && result.phone.isNotEmpty;
      });
      if (alreadyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deja ajoute',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() => _picked.add(result));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _sharePulz() async {
    final recipients = _pulzRecipients;
    if (recipients.isEmpty) return;
    setState(() => _sending = true);
    try {
      final service = ref.read(sharedEventsServiceProvider);
      await service.shareEvent(
        eventId: widget.eventId,
        toUserIds: recipients.map((p) => p.pulzUser!.userId).toList(),
      );
      ActivityService.instance.eventShared(
        eventId: widget.eventId,
        nbDestinataires: recipients.length,
      );
      ref.invalidate(sharedWithMeProvider);
      if (!mounted) return;
      setState(() {
        _sending = false;
        // Retirer les Pulz envoyes, garder les non-Pulz en attente d'invite SMS
        _picked.removeWhere((p) => p.isOnPulz);
        _sent = _picked.isEmpty;
      });
      if (!_sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${recipients.length} envoi${recipients.length > 1 ? 's' : ''} effectue${recipients.length > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage : $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _inviteBySms() async {
    final recipients = _nonPulzRecipients;
    if (recipients.isEmpty) return;
    final message =
        'Salut ! Rejoins-moi sur Pulz pour decouvrir "${widget.eventTitle}" et les events autour de toi :\n$_playStoreLink';
    await Share.share(message, subject: 'Rejoins-moi sur Pulz');
    if (!mounted) return;
    setState(() {
      _picked.removeWhere((p) => !p.isOnPulz);
      _sent = _picked.isEmpty;
    });
  }
}
