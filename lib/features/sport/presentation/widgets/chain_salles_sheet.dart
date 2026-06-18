import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/sport/data/fitness_chains.dart';

/// Ouvre une feuille listant toutes les salles d'une chaine (Basic-Fit, etc.)
/// avec leur localisation (ville · adresse), un acces Maps et un tap vers la
/// fiche detail de chaque salle. [coverUrl] = photo de pochette de la chaine
/// (table fitness_chains) ; a defaut on retombe sur le logo asset.
void showChainSallesSheet(
  BuildContext context,
  FitnessChain chain,
  List<CommerceModel> salles, {
  String? coverUrl,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ChainSallesSheet(chain: chain, salles: salles, coverUrl: coverUrl),
  );
}

class _ChainSallesSheet extends StatelessWidget {
  final FitnessChain chain;
  final List<CommerceModel> salles;
  final String? coverUrl;

  const _ChainSallesSheet({
    required this.chain,
    required this.salles,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // En-tete : logo + nom + nombre de salles.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (coverUrl != null && coverUrl!.startsWith('http'))
                        ? CachedNetworkImage(
                            imageUrl: coverUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 88,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.fitness_center, size: 22),
                          )
                        : Image.asset(
                            chain.logo,
                            fit: BoxFit.cover,
                            cacheWidth: 88,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fitness_center, size: 22),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chain.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          salles.length > 1
                              ? '${salles.length} salles'
                              : '1 salle',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Liste des salles.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: salles.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, i) {
                  final salle = salles[i];
                  final title =
                      salle.ville.isNotEmpty ? salle.ville : salle.nom;
                  final subtitle = [
                    if (salle.adresse.isNotEmpty) salle.adresse,
                    if (salle.adresse.isEmpty && salle.ville.isNotEmpty)
                      salle.ville,
                  ].join(' · ');
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: Colors.black54),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54))
                        : null,
                    trailing: salle.lienMaps.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.map_outlined,
                                color: Colors.black54),
                            tooltip: 'Maps',
                            onPressed: () => _openMaps(salle.lienMaps),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      CommerceRowCard.openDetail(
                        context,
                        salle,
                        imageAsset:
                            salle.photo.startsWith('http') ? null : chain.logo,
                        siblings: salles,
                        index: i,
                      );
                    },
                  );
                },
              ),
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
