import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/contributor_profile_sheet.dart';

/// Palette sombre fixe des ecrans coffre/invitations (cf _CoffreColors).
class _HostColors {
  static const surfaceHi = Color(0xFF241640);
  static const text = Color(0xFFF5F0FF);
  static const textDim = Color(0xFFB5A8D0);
  static const line = Color(0x12FFFFFF);
  // Meme accent or que l'organisateur dans le chat.
  static const host = Color(0xFFFFC857);
}

/// Carte "Organise par" affichee aux invites avant la liste des presents.
/// Tap -> fiche profil publique de l'organisateur.
class HostCard extends StatelessWidget {
  final PrivateEventHost host;

  const HostCard({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    final prenom = host.prenom?.trim() ?? '';
    final name = prenom.isNotEmpty ? prenom : 'Organisateur';
    final ville = host.ville?.trim() ?? '';
    final avatar = host.avatarUrl;
    final hasPhoto = avatar != null && avatar.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => ContributorProfileSheet.showPreloaded(
        context,
        profile: {
          'prenom': name,
          'avatar_url': avatar,
          'ville': host.ville,
          'bio': host.bio,
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _HostColors.surfaceHi,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _HostColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _HostColors.host, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _initial(name),
                      placeholder: (_, __) => _initial(name),
                    )
                  : _initial(name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORGANISE PAR',
                    style: GoogleFonts.geistMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _HostColors.host,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _HostColors.text,
                    ),
                  ),
                  if (ville.isNotEmpty)
                    Text(
                      ville,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        fontSize: 12,
                        color: _HostColors.textDim,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: _HostColors.textDim,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _initial(String name) => Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        alignment: Alignment.center,
        child: Text(
          name[0].toUpperCase(),
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}
