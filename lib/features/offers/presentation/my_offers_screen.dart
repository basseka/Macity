import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';

/// Ecran "Mes offres" — accessible depuis le menu compte d'un pro approuve.
/// Liste toutes ses offres (actives + expirees) avec actions modifier / supprimer.
class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(myOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Mes offres',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _primaryDarkColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primaryDarkColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _primaryColor),
            tooltip: 'Creer une offre',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddOfferBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: offersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
        error: (e, _) => Center(
          child: Text(
            'Erreur : $e',
            style: GoogleFonts.geist(color: AppColors.textFaint),
          ),
        ),
        data: (offers) {
          if (offers.isEmpty) {
            return _EmptyState(
              onCreate: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddOfferBottomSheet(),
                );
              },
            );
          }
          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: () async => ref.invalidate(myOffersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _MyOfferTile(
                offer: offers[i],
                onEdit: () => _openEdit(context, offers[i]),
                onDelete: () => _confirmDelete(context, ref, offers[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context, Offer offer) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddOfferBottomSheet(existing: offer),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Offer offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette offre ?'),
        content: Text(
          '«${offer.title}» sera definitivement supprimee. Cette action est irreversible.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await OfferSupabaseService().deleteOffer(offer.id);
      ref.invalidate(myOffersProvider);
      ref.invalidate(activeOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre supprimee'),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur suppression : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _MyOfferTile extends StatelessWidget {
  final Offer offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyOfferTile({
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.imageUrl.isNotEmpty;
    // Une offre "sans expiration" (sentinelle 2099) n'expire jamais.
    final isExpired = !offer.hasNoExpiration &&
        offer.expiresAt.isBefore(DateTime.now());
    // Une offre "illimitee" n'est jamais complete.
    final isComplete = !offer.isUnlimited && !offer.hasSpots;
    final isLive = !isExpired && !isComplete && offer.isActive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image OU emoji
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  CachedNetworkImage(
                    imageUrl: offer.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceHi),
                    errorWidget: (_, __, ___) => _emojiBg(),
                  )
                else
                  _emojiBg(),
                // Badge statut
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StatusChip(
                    isLive: isLive,
                    isExpired: isExpired,
                    isComplete: isComplete,
                  ),
                ),
              ],
            ),
          ),
          // Infos
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (offer.emoji.isNotEmpty) ...[
                      Text(
                        offer.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        offer.title,
                        style: GoogleFonts.geist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 13, color: AppColors.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      offer.isUnlimited
                          ? '${offer.claimedSpots} reclamee${offer.claimedSpots > 1 ? "s" : ""} · ∞'
                          : '${offer.claimedSpots}/${offer.totalSpots} reclamees',
                      style: GoogleFonts.geist(
                        fontSize: 11,
                        color: AppColors.textFaint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.event, size: 13, color: AppColors.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      offer.hasNoExpiration
                          ? 'Sans expiration'
                          : _formatDate(offer.expiresAt),
                      style: GoogleFonts.geist(
                        fontSize: 11,
                        color: isExpired
                            ? Colors.red.shade400
                            : AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              MyOffersScreen._primaryDarkColor,
                          side: const BorderSide(
                              color: MyOffersScreen._primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiBg() {
    return Container(
      color: const Color(0xFFF3E8FF),
      alignment: Alignment.center,
      child: Text(
        offer.emoji.isNotEmpty ? offer.emoji : '🎁',
        style: const TextStyle(fontSize: 56),
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

class _StatusChip extends StatelessWidget {
  final bool isLive;
  final bool isExpired;
  final bool isComplete;

  const _StatusChip({
    required this.isLive,
    required this.isExpired,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch ((isExpired, isComplete, isLive)) {
      (true, _, _) => ('Expiree', Colors.grey, Icons.history_rounded),
      (_, true, _) => ('Complete', Colors.orange, Icons.block_rounded),
      (_, _, true) => ('En cours', Colors.green, Icons.circle),
      _ => ('Inactive', Colors.grey, Icons.pause_circle_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
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
                color: MyOffersScreen._primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: MyOffersScreen._primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune offre encore',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MyOffersScreen._primaryDarkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cree ta premiere offre promotionnelle pour attirer plus de clients.',
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.textFaint,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Creer une offre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyOffersScreen._primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
