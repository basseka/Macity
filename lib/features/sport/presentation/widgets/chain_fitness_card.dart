import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/sport/data/fitness_chains.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Carte unique pour une chaine de salles (Basic-Fit, Fitness Park, etc.).
/// Repliee : logo + nom + nombre de salles. Depliee : liste des salles avec
/// leur localisation (adresse · ville) et un acces Maps + fiche detail.
class ChainFitnessCard extends ConsumerStatefulWidget {
  final FitnessChain chain;
  final List<CommerceModel> salles;

  const ChainFitnessCard({
    super.key,
    required this.chain,
    required this.salles,
  });

  @override
  ConsumerState<ChainFitnessCard> createState() => _ChainFitnessCardState();
}

class _ChainFitnessCardState extends ConsumerState<ChainFitnessCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);
    final count = widget.salles.length;
    final coverUrl =
        ref.watch(fitnessChainPhotosProvider).valueOrNull?[widget.chain.token];

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tete (toggle) ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: modeTheme.chipBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: (coverUrl != null && coverUrl.startsWith('http'))
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            memCacheWidth: 96,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.fitness_center,
                              color: modeTheme.primaryColor,
                              size: 22,
                            ),
                          )
                        : Image.asset(
                            widget.chain.logo,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            cacheWidth: 96,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.fitness_center,
                              color: modeTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chain.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count > 1 ? '$count salles' : '1 salle',
                          style: TextStyle(
                            fontSize: 11,
                            color: modeTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste des salles (depliee) ──
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                for (int i = 0; i < widget.salles.length; i++)
                  _SalleRow(
                    salle: widget.salles[i],
                    siblings: widget.salles,
                    index: i,
                    chainLogo: widget.chain.logo,
                    primaryColor: modeTheme.primaryColor,
                    isLast: i == widget.salles.length - 1,
                  ),
              ],
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de salle dans la chaine depliee.
class _SalleRow extends StatelessWidget {
  final CommerceModel salle;
  final List<CommerceModel> siblings;
  final int index;
  final String chainLogo;
  final Color primaryColor;
  final bool isLast;

  const _SalleRow({
    required this.salle,
    required this.siblings,
    required this.index,
    required this.chainLogo,
    required this.primaryColor,
    required this.isLast,
  });

  /// Libelle de localisation : ville si dispo, sinon nom de la salle.
  String get _title {
    if (salle.ville.isNotEmpty) return salle.ville;
    return salle.nom;
  }

  @override
  Widget build(BuildContext context) {
    final meta = [salle.adresse, if (salle.adresse.isEmpty) salle.ville]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return InkWell(
      onTap: () => CommerceRowCard.openDetail(
        context,
        salle,
        imageAsset: salle.photo.startsWith('http') ? null : chainLogo,
        siblings: siblings,
        index: index,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: TextStyle(fontSize: 11, color: AppColors.textDim),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (salle.lienMaps.isNotEmpty)
              IconButton(
                icon: Icon(Icons.map_outlined, size: 20, color: primaryColor),
                tooltip: 'Maps',
                onPressed: () => _openMaps(salle.lienMaps),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Impossible d\'ouvrir Maps: $e');
    }
  }
}
