import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/features/offers/data/subscription_interest_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/subscription_screen.dart';

/// Detail plein ecran d'une offre. S'ouvre quand l'utilisateur tap une carte
/// dans l'ExplorerScreen. Le CTA "J'en profite" est un placeholder dont le
/// comportement sera defini ulterieurement (loterie, validation directe,
/// etc.).
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
          SliverAppBar(
            expandedHeight: 320,
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
                      errorWidget: (_, __, ___) => _emojiHero(),
                    )
                  else
                    _emojiHero(),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          offer.title,
                          style: GoogleFonts.geist(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  if (offer.description.isNotEmpty)
                    Text(
                      offer.description,
                      style: GoogleFonts.geist(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Bloc commerce
                  _InfoBlock(
                    icon: Icons.storefront_rounded,
                    label: 'Chez',
                    value: offer.businessName,
                    subValue: offer.businessAddress.isNotEmpty
                        ? offer.businessAddress
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Bloc validite
                  _InfoBlock(
                    icon: Icons.event_available_rounded,
                    label: 'Valable',
                    value: offer.hasNoExpiration
                        ? 'Sans date limite'
                        : 'jusqu\'au ${_formatDate(offer.expiresAt)}',
                  ),
                  const SizedBox(height: 14),

                  // Bloc places
                  _InfoBlock(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Disponibilite',
                    value: offer.isUnlimited
                        ? 'Places illimitees'
                        : (offer.hasSpots
                            ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''} sur ${offer.totalSpots}'
                            : 'Complet'),
                    valueColor: offer.isUnlimited
                        ? const Color(0xFFE8A0BF)
                        : (offer.hasSpots
                            ? const Color(0xFFE8A0BF)
                            : Colors.red.shade300),
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
                // "J'en profite" -> proposition d'abonnement BeThere
                // Premium 5 EUR/mois pour debloquer toutes les offres.
                // Toujours actif (meme sur offre complete) : l'abonnement
                // ne concerne pas une offre specifique mais l'acces global.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
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

  Widget _emojiHero() {
    return ColoredBox(
      color: const Color(0xFF241338),
      child: Center(
        child: Text(
          offer.emoji.isNotEmpty ? offer.emoji : '🎁',
          style: const TextStyle(fontSize: 96),
        ),
      ),
    );
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

  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE8A0BF), size: 20),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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
        ],
      ),
    );
  }
}
