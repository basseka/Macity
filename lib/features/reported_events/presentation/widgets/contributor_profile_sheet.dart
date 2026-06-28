import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';

/// Fiche d'un contributeur de story : grande photo + prenom + ville + bio.
/// Ouverte au tap sur l'avatar dans le viewer. Le profil public est recupere
/// via le RPC `get_public_profile` (uniquement champs non sensibles).
class ContributorProfileSheet extends StatefulWidget {
  final String userId;
  final String fallbackPrenom;
  final String? fallbackAvatarUrl;

  const ContributorProfileSheet({
    super.key,
    required this.userId,
    required this.fallbackPrenom,
    this.fallbackAvatarUrl,
  });

  /// Ouvre la fiche en bottom sheet. No-op si [userId] est vide (anonyme).
  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String fallbackPrenom,
    String? fallbackAvatarUrl,
  }) {
    if (userId.isEmpty) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ContributorProfileSheet(
        userId: userId,
        fallbackPrenom: fallbackPrenom,
        fallbackAvatarUrl: fallbackAvatarUrl,
      ),
    );
  }

  @override
  State<ContributorProfileSheet> createState() =>
      _ContributorProfileSheetState();
}

class _ContributorProfileSheetState extends State<ContributorProfileSheet> {
  final _service = UserProfileService();
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchPublicProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14111C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          final profile = snap.data;
          final prenom = (profile?['prenom'] as String?)?.trim().isNotEmpty == true
              ? (profile!['prenom'] as String).trim()
              : (widget.fallbackPrenom.isNotEmpty
                  ? widget.fallbackPrenom
                  : 'Anonyme');
          final avatar = (profile?['avatar_url'] as String?)?.isNotEmpty == true
              ? profile!['avatar_url'] as String
              : widget.fallbackAvatarUrl;
          final ville = (profile?['ville'] as String?)?.trim() ?? '';
          final bio = (profile?['bio'] as String?)?.trim() ?? '';
          final loading = snap.connectionState == ConnectionState.waiting;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignee
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _Avatar(initial: _initialOf(prenom), url: avatar),
              const SizedBox(height: 12),
              Text(
                prenom,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (ville.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  ville,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                )
              else
                Text(
                  bio.isNotEmpty ? bio : "Ce membre n'a pas encore de bio.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: bio.isNotEmpty
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _initialOf(String prenom) =>
      prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? url;
  const _Avatar({required this.initial, this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasUrl
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.magenta, AppColors.violet],
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              errorWidget: (_, __, ___) => _initialText(),
            )
          : _initialText(),
    );
  }

  Widget _initialText() => Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
}
