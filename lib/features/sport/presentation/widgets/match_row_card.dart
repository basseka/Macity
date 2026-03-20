import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Carte match : [ecusson gauche] [texte VS] [ecusson droite]
class MatchRowCard extends ConsumerWidget {
  final SupabaseMatch match;

  const MatchRowCard({super.key, required this.match});

  /// Ecussons par nom d'equipe (lowercase match partiel).
  static const _teamAffiches = <String, String>{
    // Pro D2
    'colomiers': 'assets/images/ecu_colomiers.png',
    'brive': 'assets/images/ecu_brive.png',
    'dax': 'assets/images/ecu_dax.png',
    'carcassonne': 'assets/images/ecu_carcassonne.png',
    'mont-de-marsan': 'assets/images/ecu_montdemarcon.png',
    'beziers': 'assets/images/ecu_beziers.png',
    'béziers': 'assets/images/ecu_beziers.png',
    'biarritz': 'assets/images/ecu_biarritz.png',
    'grenoble': 'assets/images/ecu_grenoble.png',
    'oyonnax': 'assets/images/ecu_oyonnax.png',
    'provence': 'assets/images/ecu_provence.png',
    'vannes': 'assets/images/ecu_vannes.png',
    'agen': 'assets/images/ecu_agen.png',
    'angouleme': 'assets/images/ecu_angouleme.png',
    'angoulême': 'assets/images/ecu_angouleme.png',
    'aurillac': 'assets/images/ecu_aurillac.png',
    'nevers': 'assets/images/ecu_nevers.png',
    'valence': 'assets/images/ecu_valence.png',
    // Toulouse FC / Fenix (avant Top 14 car "toulouse" contient "lou")
    'toulouse fc': 'assets/images/ecu_toulouseFC.png',
    'toulouse football': 'assets/images/ecu_toulouseFC.png',
    'tfc': 'assets/images/ecu_toulouseFC.png',
    'fenix': 'assets/images/ecu_fenix.png',
    // Top 14
    'stade toulousain': 'assets/images/ecussion_toulouse.png',
    'montpellier': 'assets/images/ecussion_montpellier.png',
    'lou': 'assets/images/ecussion_lyon.png',
    'lyon': 'assets/images/ecussion_lyon.png',
    'clermont': 'assets/images/ecussion_clermont.png',
    'bayonne': 'assets/images/ecussion_bayonne.png',
    'castres': 'assets/images/ecussion_castres.png',
    'toulon': 'assets/images/ecussion_toulon.png',
    'racing': 'assets/images/ecussion_racing92.png',
    'pau': 'assets/images/ecussion_pau.png',
    'stade français': 'assets/images/ecussion_paris.png',
    'stade francais': 'assets/images/ecussion_paris.png',
    'la rochelle': 'assets/images/ecussion_larochelle.png',
    'montauban': 'assets/images/ecussion_montauban.png',
    'perpignan': 'assets/images/ecussion_perpignan.png',
    'bordeaux': 'assets/images/ecussion_bordeaux.png',
    // Champions Cup
    'bristol': 'assets/images/ecussion_bristol.png',
  };

  static String? _teamAffiche(String teamName) {
    final lower = teamName.toLowerCase();
    for (final entry in _teamAffiches.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static const _sportImages = <String, String>{
    'football': 'assets/images/pochette_football.png',
    'foot': 'assets/images/pochette_football.png',
    'rugby': 'assets/images/pochette_rugby.png',
    'basket': 'assets/images/pochette_basketball.png',
    'handball': 'assets/images/pochette_handball.png',
    'boxe': 'assets/images/pochette_boxe.png',
    'natation': 'assets/images/pochette_natation.png',
    'course': 'assets/images/pochette_courseapied.png',
    'golf': 'assets/images/pochette_course.png',
    'fitness': 'assets/images/pochette_fitness.png',
  };

  String _resolveImage() {
    final equipe = match.equipe1.toLowerCase();
    if (equipe.contains('stade toulousain')) {
      return 'assets/images/pochette_rugby-st.png';
    }
    if (equipe.contains('colomiers') && match.sport.toLowerCase().contains('rugby')) {
      return 'assets/images/pochette_rugby-colomiers.png';
    }
    if (equipe.contains('tmb')) {
      return 'assets/images/pochette_basketball-tmb.png';
    }
    if (equipe.contains('tbc') || equipe.contains('toulouse bc')) {
      return 'assets/images/pochette_basketball-tbc.png';
    }
    if (equipe.contains('fenix')) {
      return 'assets/images/pochette_handball-fenix.png';
    }
    if (equipe.contains('tfc') || equipe.contains('toulouse fc')) {
      return 'assets/images/pochette_football-tfc.png';
    }
    if (match.billetterie.contains('uscnat.fr')) {
      return 'assets/images/pochette_natation-usc.png';
    }

    final sport = match.sport.toLowerCase();
    final comp = match.competition.toLowerCase();
    for (final entry in _sportImages.entries) {
      if (sport.contains(entry.key) || comp.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/sc_autres_sport.png';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final sportLower = match.sport.toLowerCase();
    final isNatation = sportLower.contains('natation');
    final isCourse = sportLower.contains('course');
    final isEventSport = isNatation || isCourse;
    // Priorité : logo de la BDD, sinon fallback local, sinon photo user event
    final ecu1 = match.logoDom.isNotEmpty
        ? match.logoDom
        : isNatation ? 'assets/images/ecu_natation.png'
        : _teamAffiche(match.equipe1) ?? (match.photoUrl.isNotEmpty ? match.photoUrl : null);
    final ecu2 = match.logoExt.isNotEmpty
        ? match.logoExt
        : (match.equipe2.isNotEmpty && !isEventSport ? _teamAffiche(match.equipe2) : null);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Ecusson gauche (equipe 1) ──
              _buildEcusson(ecu1),

              const SizedBox(width: 12),

              // ── Texte central ──
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Competition badge
                    if (match.competition.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: modeTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          match.competition,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: modeTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Equipe 1
                    Text(
                      match.equipe1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // VS
                    if (match.equipe2.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: modeTheme.primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                    // Equipe 2
                    if (match.equipe2.isNotEmpty)
                      Text(
                        match.equipe2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 6),

                    // Date + heure
                    if (match.date.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 11, color: Colors.white54),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              match.heure.isNotEmpty
                                  ? '${_formatDate(match.date)} - ${match.heure}'
                                  : _formatDate(match.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Lieu
                    if (match.lieu.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 11, color: Colors.white38),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                match.lieu,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Badge GRATUIT
                    if (match.gratuit.toLowerCase() == 'oui')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'GRATUIT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Ecusson 56x56 : URL reseau (BDD) ou asset local, sinon icone par defaut.
  Widget _buildEcusson(String? ecussonPath) {
    if (ecussonPath == null || ecussonPath.isEmpty) return _defaultSportIcon();

    if (ecussonPath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: ecussonPath,
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          placeholder: (_, __) => _defaultSportIcon(),
          errorWidget: (_, __, ___) => _defaultSportIcon(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        ecussonPath,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _defaultSportIcon(),
      ),
    );
  }

  Widget _defaultSportIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.sports, size: 28, color: Colors.white24),
    );
  }

  void _openDetail(BuildContext context) {
    final isNat = match.sport.toLowerCase().contains('natation');
    final equipe1Lower = match.equipe1.toLowerCase();
    final isRugby = match.sport.toLowerCase().contains('rugby');
    final isColomiers = equipe1Lower.contains('colomiers') && isRugby;
    final isStadeToulousain = equipe1Lower.contains('stade toulousain') && isRugby;
    final isFenix = equipe1Lower.contains('fenix');
    final image = isNat
        ? 'assets/images/detail_toulouse_natation.png'
        : isFenix
            ? 'assets/images/detail_fenix_hand.png'
            : isStadeToulousain
            ? 'assets/images/detail_stadetoulousain_rugby.png'
            : isColomiers
                ? 'assets/images/detail_colomier_rugby.png'
                : _resolveImage();
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: match.equipe2.isNotEmpty
            ? '${match.equipe1}  vs  ${match.equipe2}'
            : match.equipe1,
        imageAsset: image,
        imageUrl: match.photoUrl.isNotEmpty ? match.photoUrl : null,
        infos: [
          if (match.sport.isNotEmpty)
            DetailInfoItem(Icons.sports, match.sport),
          if (match.competition.isNotEmpty)
            DetailInfoItem(Icons.emoji_events_outlined, match.competition),
          if (match.date.isNotEmpty)
            DetailInfoItem(
              Icons.calendar_today,
              match.heure.isNotEmpty
                  ? '${_formatDate(match.date)} - ${match.heure}'
                  : _formatDate(match.date),
            ),
          if (match.lieu.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, match.lieu),
          if (match.ville.isNotEmpty)
            DetailInfoItem(Icons.location_city, match.ville),
          if (match.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, match.description),
          if (match.gratuit.toLowerCase() == 'oui')
            DetailInfoItem(Icons.money_off, 'Gratuit'),
        ],
        primaryAction: match.billetterie.isNotEmpty
            ? DetailAction(
                icon: Icons.confirmation_number_outlined,
                label: 'Billetterie',
                url: match.billetterie,
              )
            : null,
        shareText: _buildShareText(),
      ),
    );
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('${match.equipe1} vs ${match.equipe2}');
    if (match.competition.isNotEmpty) buffer.writeln(match.competition);
    if (match.date.isNotEmpty) buffer.writeln('Date: ${match.date}');
    if (match.lieu.isNotEmpty) buffer.writeln('Lieu: ${match.lieu}');
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return raw;
  }
}
