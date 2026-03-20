import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/day/data/shared_events_service.dart';
import 'package:pulz_app/features/day/state/shared_events_provider.dart';

/// Bottom sheet pour partager un event avec des contacts in-app.
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
  final _selected = <String>{}; // user_ids selectionnes
  bool _sending = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(appContactsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF6C5CE7), size: 22),
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
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Content
          Flexible(
            child: _sent
                ? _buildSentState()
                : contactsAsync.when(
                    data: (contacts) {
                      if (contacts.isEmpty) return _buildNoContacts();
                      return _buildContactsList(contacts);
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
                            'Detection des contacts...',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    error: (_, __) => _buildNoContacts(),
                  ),
          ),

          // Send button
          if (!_sent)
            contactsAsync.whenData((contacts) {
                  if (contacts.isEmpty) return null;
                  return true;
                }).valueOrNull ==
                true
            ? _buildSendButton()
            : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<AppContact> contacts) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: Colors.grey.shade100),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = _selected.contains(contact.userId);
        final displayName = contact.contactName ?? contact.prenom;

        return ListTile(
          onTap: () => setState(() {
            if (isSelected) {
              _selected.remove(contact.userId);
            } else {
              _selected.add(contact.userId);
            }
          }),
          leading: CircleAvatar(
            backgroundColor: isSelected
                ? const Color(0xFF6C5CE7)
                : const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ),
          ),
          title: Text(
            displayName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          subtitle: contact.prenom.isNotEmpty && contact.contactName != null
              ? Text(
                  contact.prenom,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                )
              : null,
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _selected.isEmpty || _sending ? null : _share,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              disabledBackgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _selected.isEmpty
                        ? 'Selectionner des contacts'
                        : 'Partager avec ${_selected.length} personne${_selected.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selected.isEmpty ? Colors.grey.shade400 : Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoContacts() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.contacts_outlined, size: 30, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contact sur M-City',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite tes amis a telecharger l\'app\npour partager des events !',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => Share.share(
                'Rejoins-moi sur M-City pour decouvrir les events autour de toi !\nhttps://play.google.com/apps/internaltest/4700923192632434389',
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                'Inviter un ami',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
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
            child: const Icon(Icons.check_circle_rounded, size: 36, color: Color(0xFF4CAF50)),
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
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C5CE7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sending = true);
    try {
      final service = ref.read(sharedEventsServiceProvider);
      await service.shareEvent(
        eventId: widget.eventId,
        toUserIds: _selected.toList(),
      );
      ActivityService.instance.eventShared(
        eventId: widget.eventId,
        nbDestinataires: _selected.length,
      );
      ref.invalidate(sharedWithMeProvider);
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }
}
