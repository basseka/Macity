import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/notifications/data/mairie_notifications_service.dart';
import 'package:pulz_app/features/notifications/state/mairie_notifications_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class MairieNotificationsSheet extends ConsumerWidget {
  const MairieNotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MairieNotificationsSheet(),
    );
  }

  static final _dateFormat = DateFormat('dd/MM/yyyy a HH:mm', 'fr_FR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villeAsync = ref.watch(userVilleProvider);
    final city = villeAsync.valueOrNull?.replaceAll(RegExp(r'\s*\(.*\)$'), '') ?? '';
    final notifAsync = ref.watch(mairieNotificationsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
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
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mairie de $city',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A0A2E),
                        ),
                      ),
                      Text(
                        'Notifications officielles',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
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
            child: notifAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return _buildEmpty(city);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _NotificationCard(notification: notifications[index]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1565C0),
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Erreur de chargement',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(mairieNotificationsProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String city) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'La Mairie de $city n\'a pas encore publie de notification',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final MairieNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = notification.photoUrl != null && notification.photoUrl!.isNotEmpty;
    final hasLink = notification.linkUrl != null && notification.linkUrl!.isNotEmpty;
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return GestureDetector(
      onTap: hasLink ? () => _openLink(notification.linkUrl!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (hasPhoto)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: notification.photoUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time + badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance, size: 12, color: Color(0xFF1565C0)),
                            const SizedBox(width: 4),
                            Text(
                              'Mairie',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A2E),
                      height: 1.3,
                    ),
                  ),

                  // Body
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Link
                  if (hasLink) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: const Color(0xFF1565C0).withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          'En savoir plus',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return MairieNotificationsSheet._dateFormat.format(date);
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
