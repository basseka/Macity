import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/features/offers/data/subscription_interest_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/offer_code_popup.dart';

/// Detail plein ecran d'une offre. S'ouvre quand l'utilisateur tap une carte
/// dans l'ExplorerScreen. Le CTA "J'en profite" reclame une place et ouvre
/// [OfferCodePopup], qui affiche le QR a presenter au commercant.
class OfferDetailScreen extends StatelessWidget {
  final Offer offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: CustomScrollView(
        slivers: [
          // ─── Hero image avec back button ───
          // 200 et non 320 : au-dela, le titre, la description et les 3 blocs
          // d'info passaient sous le pli sur la plupart des telephones,
          // obligeant a scroller pour voir l'essentiel de l'offre des l'ouverture.
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A0A2E),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: offer.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFF241338),
                      ),
                      errorWidget: (_, __, ___) => _EmojiHero(emoji: offer.emoji),
                    )
                  else
                    _EmojiHero(emoji: offer.emoji),
                  // Degrade pour lisibilite du titre overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A0A2E).withValues(alpha: 0.95),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Badge places restantes en haut a droite
                  Positioned(
                    top: 56,
                    right: 16,
                    child: _SpotsBadge(offer: offer),
                  ),
                ],
              ),
            ),
          ),

          // ─── Contenu scrollable ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + emoji
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (offer.emoji.isNotEmpty) ...[
                        Text(
                          offer.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          offer.title,
                          style: GoogleFonts.geist(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (offer.description.isNotEmpty)
                    Text(
                      offer.description,
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),

                  // Bloc commerce : tap ouvre la photo de l'offre en grand
                  // + un lien Maps pour s'y rendre.
                  GestureDetector(
                    onTap: () => _showBusinessSheet(context),
                    child: _InfoBlock(
                      icon: Icons.storefront_rounded,
                      label: 'Chez',
                      value: offer.businessName,
                      subValue: offer.businessAddress.isNotEmpty
                          ? offer.businessAddress
                          : null,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Validite + places : regroupees sur une ligne (au lieu de 2
                  // blocs empiles) pour tenir dans la hauteur visible sans
                  // scroller.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          icon: Icons.event_available_rounded,
                          label: 'Valable',
                          value: offer.hasNoExpiration
                              ? 'Sans date limite'
                              : 'jusqu\'au ${_formatDate(offer.expiresAt)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoBlock(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Disponibilite',
                          value: offer.isUnlimited
                              ? 'Illimitees'
                              : (offer.hasSpots
                                  ? '${offer.remainingSpots} / ${offer.totalSpots}'
                                  : 'Complet'),
                          valueColor: offer.isUnlimited
                              ? const Color(0xFFE8A0BF)
                              : (offer.hasSpots
                                  ? const Color(0xFFE8A0BF)
                                  : Colors.red.shade300),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── CTA "J'en profite" fixe en bas ───
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Tracking intérêt (fire-and-forget, n'attend pas).
                SubscriptionInterestService().trackEnProfite(
                  offerId: offer.id,
                  offerTitle: offer.title,
                  ville: offer.city,
                );
                // "J'en profite" reclame la place et affiche le QR a
                // presenter au commercant. Le popup gere lui-meme les refus
                // (offre pleine, expiree) et le cas du code deja obtenu.
                OfferCodePopup.show(context, offer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EditorialColors.gold,
                foregroundColor: const Color(0xFF1A0A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'J\'en profite',
                style: GoogleFonts.geist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvre la photo de l'offre en plein ecran, avec le CTA itineraire par-
  /// dessus. Remplace l'ancienne bottom sheet : la demande explicite etait
  /// "ouvre l'offre en plein ecran", pas un panneau partiel.
  void _showBusinessSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _OfferPhotoFullScreen(
          offer: offer,
          onItinerary: _openItinerary,
          onCall: _callPhone,
        ),
      ),
    );
  }

  /// Ouvre Google Maps en itineraire vers le commerce. Recherche texte
  /// (nom + adresse) plutot que lat/lng : l'offre n'a pas de coordonnees,
  /// seulement les champs libres saisis dans admin.html.
  Future<void> _openItinerary() async {
    final destination = offer.businessAddress.isNotEmpty
        ? '${offer.businessName} ${offer.businessAddress}'
        : offer.businessName;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Ouvre le composeur telephonique du device sur le numero du commerce.
  Future<void> _callPhone() async {
    final uri = Uri(scheme: 'tel', path: offer.businessPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String _formatDate(DateTime d) {
    const months = [
      'janv.', 'fevr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'aout', 'sept.', 'oct.', 'nov.', 'dec.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SpotsBadge extends StatelessWidget {
  final Offer offer;

  const _SpotsBadge({required this.offer});

  @override
  Widget build(BuildContext context) {
    final hasSpots = offer.hasSpots;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasSpots
            ? const Color(0xFFE8A0BF).withValues(alpha: 0.22)
            : Colors.red.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasSpots
              ? const Color(0xFFE8A0BF).withValues(alpha: 0.45)
              : Colors.red.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        offer.isUnlimited
            ? '∞ Illimite'
            : (hasSpots
                ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''}'
                : 'Complet'),
        style: GoogleFonts.geist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasSpots
              ? const Color(0xFFE8A0BF)
              : Colors.red.shade300,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE8A0BF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.geist(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue!,
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Fallback affiche quand l'offre n'a pas de photo (hero, plein ecran).
class _EmojiHero extends StatelessWidget {
  final String emoji;

  const _EmojiHero({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF241338),
      child: Center(
        child: Text(
          emoji.isNotEmpty ? emoji : '🎁',
          style: const TextStyle(fontSize: 96),
        ),
      ),
    );
  }
}

/// Photo de l'offre en plein ecran (tap sur le bloc "Chez"), avec un CTA
/// itineraire superpose en bas : pas de panneau partiel, la photo occupe
/// tout l'ecran comme demande.
class _OfferPhotoFullScreen extends StatelessWidget {
  final Offer offer;
  final Future<void> Function() onItinerary;
  final Future<void> Function() onCall;

  const _OfferPhotoFullScreen({
    required this.offer,
    required this.onItinerary,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: offer.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: offer.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) =>
                          _EmojiHero(emoji: offer.emoji),
                      errorWidget: (_, __, ___) =>
                          _EmojiHero(emoji: offer.emoji),
                    )
                  : _EmojiHero(emoji: offer.emoji),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.businessName,
                      style: GoogleFonts.geist(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (offer.businessAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        offer.businessAddress,
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: onItinerary,
                        icon: const Icon(Icons.directions_rounded),
                        label: Text(
                          'Itinéraire',
                          style: GoogleFonts.geist(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EditorialColors.gold,
                          foregroundColor: const Color(0xFF1A0A2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (offer.businessPhone.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call_rounded),
                          label: Text(
                            offer.businessPhone,
                            style: GoogleFonts.geist(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
