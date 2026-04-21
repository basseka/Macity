import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/notifications/data/mairie_notifications_service.dart';
import 'package:pulz_app/features/notifications/presentation/manage_mairies_sheet.dart';
import 'package:pulz_app/features/notifications/state/mairie_notifications_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart'
    show userVilleProvider, userVillesNotificationsProvider;

class MairieNotificationsSheet extends ConsumerStatefulWidget {
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

  static const _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A1259), Color(0xFF7B2D8E), Color(0xFFE91E8C)],
  );

  @override
  ConsumerState<MairieNotificationsSheet> createState() =>
      _MairieNotificationsSheetState();
}

class _MairieNotificationsSheetState
    extends ConsumerState<MairieNotificationsSheet> {
  /// null = show all, otherwise filter by this ville
  String? _selectedVille;

  @override
  Widget build(BuildContext context) {
    final villesAsync = ref.watch(userVillesNotificationsProvider);
    final villes = villesAsync.valueOrNull ?? [];
    final city = villes.isNotEmpty
        ? villes
            .map((v) => v.replaceAll(RegExp(r'\s*\(.*\)$'), ''))
            .join(', ')
        : ref
                .watch(userVilleProvider)
                .valueOrNull
                ?.replaceAll(RegExp(r'\s*\(.*\)$'), '') ??
            '';
    final notifAsync = ref.watch(mairieNotificationsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF0FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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

          // Hero header
          _buildHeroHeader(city, villes, notifAsync),

          // Content
          Flexible(
            child: notifAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return _buildEmpty(city);
                }

                // Utiliser toutes les villes sélectionnées dans les préférences
                final distinctVilles = villes
                    .map((v) => v.replaceAll(RegExp(r'\s*\(.*\)$'), ''))
                    .toSet()
                    .toList()
                  ..sort();

                // Filter notifications
                final filtered = _selectedVille == null
                    ? notifications
                    : notifications
                        .where((n) =>
                            n.ville
                                .replaceAll(RegExp(r'\s*\(.*\)$'), '') ==
                            _selectedVille)
                        .toList();

                return Column(
                  children: [
                    // Ville filter chips (only if more than 1 ville)
                    if (distinctVilles.length >= 1)
                      _buildVilleFilterBar(distinctVilles, filtered.length),

                    // Notification list
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyFilter()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final notif = filtered[index];
                                final isFirst = index == 0;
                                return Padding(
                                  padding:
                                      EdgeInsets.only(top: isFirst ? 0 : 14),
                                  child: _NotificationCard(
                                    notification: notif,
                                    isLatest: isFirst,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF7B2D8E),
                        strokeWidth: 2.5,
                        backgroundColor: const Color(0xFF7B2D8E).withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des actus...',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi_off_rounded, size: 28, color: Colors.orange),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Oups, pas de connexion',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Impossible de charger les notifications',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => ref.invalidate(mairieNotificationsProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: MairieNotificationsSheet._headerGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Reessayer',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  Widget _buildHeroHeader(
    String city,
    List<String> villes,
    AsyncValue<List<MairieNotification>> notifAsync,
  ) {
    final count = notifAsync.valueOrNull?.length ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: MairieNotificationsSheet._headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2D8E).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // City icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  villes.length > 1 ? 'Mes Villes' : 'Ma Ville',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  city.isNotEmpty ? city : 'Aucune ville',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Count badge
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    count == 1 ? 'actu' : 'actus',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

          // Bouton gestion mairies (ajout / suppression)
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ManageMairiesSheet.show(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVilleFilterBar(List<String> villes, int filteredCount) {
    final allItems = [null, ...villes]; // null = "Toutes"

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: allItems.map((ville) {
          final isAll = ville == null;
          final label = isAll ? 'Toutes' : ville;
          final isSelected = _selectedVille == ville;

          return GestureDetector(
            onTap: () => setState(() => _selectedVille = ville),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? MairieNotificationsSheet._headerGradient
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFF7B2D8E).withValues(alpha: 0.2)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7B2D8E).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAll
                        ? Icons.filter_list_rounded
                        : Icons.location_city_rounded,
                    size: 11,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF7B2D8E).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF7B2D8E).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune actu pour cette mairie',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF7B2D8E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_rounded,
              size: 34,
              color: const Color(0xFF7B2D8E).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Rien de neuf !',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            city.isNotEmpty
                ? '$city n\'a pas encore publie d\'actualite'
                : 'Aucune actualite pour le moment',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2D8E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 14, color: const Color(0xFF7B2D8E).withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tu seras notifie des nouveautes',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF7B2D8E).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification card ──

class _NotificationCard extends StatelessWidget {
  final MairieNotification notification;
  final bool isLatest;

  const _NotificationCard({
    required this.notification,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        notification.photoUrl != null && notification.photoUrl!.isNotEmpty;
    final hasLink =
        notification.linkUrl != null && notification.linkUrl!.isNotEmpty;
    final timeAgo = _formatTimeAgo(notification.createdAt);
    final villeName = notification.ville.replaceAll(RegExp(r'\s*\(.*\)$'), '');

    return GestureDetector(
      onTap: hasLink ? () => _openLink(notification.linkUrl!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isLatest
              ? Border.all(color: const Color(0xFFE91E8C).withValues(alpha: 0.3), width: 1.5)
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: isLatest
                  ? const Color(0xFF7B2D8E).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isLatest ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with overlay
            if (hasPhoto)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(17)),
                    child: CachedNetworkImage(
                      imageUrl: notification.photoUrl!,
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17)),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // "NEW" badge if latest
                  if (isLatest)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEE5A24).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'NOUVEAU',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  // Time badge on photo
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(14, hasPhoto ? 12 : 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ville tag + time (if no photo)
                  Row(
                    children: [
                      _buildVilleTag(villeName),
                      const Spacer(),
                      if (!hasPhoto)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLatest) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEE5A24),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              timeAgo,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),

                  // Body
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Link button
                  if (hasLink) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2D8E).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'En savoir plus',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildVilleTag(String villeName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7B2D8E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_city_rounded,
              size: 11, color: Color(0xFF7B2D8E)),
          const SizedBox(width: 4),
          Text(
            villeName,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7B2D8E),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'A l\'instant';
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
