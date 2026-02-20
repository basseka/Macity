import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Fiche detail d'un favori (commerce ou event) — popup plein ecran.
class LikedItemDetailSheet extends ConsumerWidget {
  final CommerceModel? _commerce;
  final Event? _event;

  const LikedItemDetailSheet.forCommerce(CommerceModel commerce, {super.key})
      : _commerce = commerce,
        _event = null;

  const LikedItemDetailSheet.forEvent(Event event, {super.key})
      : _commerce = null,
        _event = event;

  static const _primaryColor = Color(0xFF7B2D8E);

  static final _displayDateFormat = DateFormat('dd/MM/yyyy');

  // ── Image maps (memes que EventRowCard / CommerceRowCard) ──

  static const _categoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'spectacle': 'assets/images/pochette_spectacle.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'expo': 'assets/images/pochette_culture_art.png',
    'exposition': 'assets/images/pochette_culture_art.png',
    'vernissage': 'assets/images/pochette_culture_art.png',
    'visite': 'assets/images/pochette_visite.png',
    'atelier': 'assets/images/pochette_culture_art.png',
    'animation': 'assets/images/pochette_animation.png',
    'musee': 'assets/images/pochette_visite.png',
    'concert live': 'assets/images/pochette_concert.png',
  };

  static const _venueImages = <String, String>{
    'augustins': 'assets/images/augustin_musee.png',
    'abattoirs': 'assets/images/abbatoirs_musee.png',
    'bemberg': 'assets/images/fondationbemberg_musee.png',
    'paul-dupuy': 'assets/images/pauldupuy_musee.png',
    'paul dupuy': 'assets/images/pauldupuy_musee.png',
    'saint-raymond': 'assets/images/saintraymond_musee.png',
    'vieux toulouse': 'assets/images/vieuxtoulouse_musee.png',
    'histoire de la medecine': 'assets/images/histoiredelamedecine_musee.png',
    'resistance': 'assets/images/museedelaresistance_musee.png',
    'georges labit': 'assets/images/georgeslabit_musee.png',
    'museum de toulouse': 'assets/images/museum_musee.png',
    'jardins du museum': 'assets/images/jardindumuseum_musee.png',
    "cite de l'espace": 'assets/images/citeespace_museum.png',
    'aeroscopia': 'assets/images/aeroscopia_musee.png',
    'envol des pionniers': 'assets/images/envoldespionniers_musee.png',
    'halle de la machine': 'assets/images/halledelamachine_musee.png',
    'espace patrimoine': 'assets/images/espacepatrimoine_musee.png',
    "chateau d'eau": 'assets/images/chateaudeau_musee.png',
    'zenith': 'assets/images/salle_zenith.png',
    'metronum': 'assets/images/pochette_metronum.png',
    'bikini': 'assets/images/salle_bikini.png',
    'halle aux grains': 'assets/images/salle_halleauxgrains.png',
    'saint-pierre-des-cuisines': 'assets/images/pochette_saintpierre.png',
    'nougaro': 'assets/images/salle_nougaro.png',
    'taquin': 'assets/images/salle_taquin.png',
    'rex': 'assets/images/pochette_rex.png',
    'interference': 'assets/images/salle_interference.png',
    'auditorium': 'assets/images/salle_auditorium.png',
    'chapelle du chu': 'assets/images/salle_chapelle.png',
    'hotel-dieu': 'assets/images/salle_chapelle.png',
    'palais consulaire': 'assets/images/salle_palaisconsulaire.png',
    'chapelle des carmelites': 'assets/images/salle_chapelle.png',
    'casino barriere': 'assets/images/casino_barriere.png',
    'hall 8': 'assets/images/hall8.png',
    'espace job': 'assets/images/espacejob.png',
    'bascala': 'assets/images/bascala.png',
  };

  static const _commerceImages = <String, String>{
    'apero toulousain': 'assets/images/sos_aperotoulousain.png',
    'speed apero': 'assets/images/sos_speedapero.png',
    'apero eclair': 'assets/images/sos_aperoeclair.png',
    'apero speed': 'assets/images/sos_aperospeed.png',
    'allo apero': 'assets/images/sos_alloapero.png',
    'bar': 'assets/images/sc_pub.png',
    'pub': 'assets/images/sc_pub.png',
    'club': 'assets/images/sc_discotheque.png',
    'discotheque': 'assets/images/sc_discotheque.png',
    'restaurant': 'assets/images/pochette_food.png',
    'hotel': 'assets/images/sc_hotel.png',
    'chicha': 'assets/images/sc_chicha.png',
    'tabac': 'assets/images/sc_tabac_nuit.png',
    'epicerie': 'assets/images/sc_tabac_nuit.png',
  };

  String _resolveEventImage(Event event) {
    final lieu = event.lieuNom.toLowerCase();
    for (final entry in _venueImages.entries) {
      if (lieu.contains(entry.key)) return entry.value;
    }
    final cat = event.categorie.toLowerCase();
    final type = event.type.toLowerCase();
    if (_categoryImages.containsKey(cat)) return _categoryImages[cat]!;
    if (_categoryImages.containsKey(type)) return _categoryImages[type]!;
    for (final entry in _categoryImages.entries) {
      if (cat.contains(entry.key) || type.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/pochette_concert.png';
  }

  String _resolveCommerceImage(CommerceModel commerce) {
    final cat = commerce.categorie.toLowerCase();
    final nom = commerce.nom.toLowerCase();
    for (final entry in _commerceImages.entries) {
      if (cat.contains(entry.key) || nom.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/sc_pub.png';
  }

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _displayDateFormat.format(parsed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commerce = _commerce;
    if (commerce != null) {
      return _buildPopup(
        context: context,
        ref: ref,
        image: _resolveCommerceImage(commerce),
        title: commerce.nom,
        emoji: commerce.categoryEmoji,
        likeId: 'night_${commerce.nom}',
        infos: [
          if (commerce.categorie.isNotEmpty)
            _InfoItem(Icons.category_outlined, commerce.categorie),
          if (commerce.horaires.isNotEmpty)
            _InfoItem(Icons.access_time, commerce.horaires),
          if (commerce.adresse.isNotEmpty)
            _InfoItem(Icons.location_on_outlined, commerce.adresse),
          if (commerce.telephone.isNotEmpty)
            _InfoItem(Icons.phone_outlined, commerce.telephone),
        ],
        primaryAction: commerce.siteWeb.isNotEmpty
            ? _ActionButton(
                icon: Icons.language,
                label: 'Site web',
                url: commerce.siteWeb,
              )
            : null,
        secondaryActions: [
          if (commerce.lienMaps.isNotEmpty)
            _ActionButton(
              icon: Icons.map_outlined,
              label: 'Maps',
              url: commerce.lienMaps,
            ),
          if (commerce.telephone.isNotEmpty)
            _ActionButton(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              url: 'tel:${commerce.telephone.replaceAll(' ', '')}',
            ),
        ],
        shareText: _buildCommerceShareText(commerce),
      );
    }
    final event = _event;
    if (event == null) return const SizedBox.shrink();
    return _buildPopup(
      context: context,
      ref: ref,
      image: _resolveEventImage(event),
      title: event.titre,
      emoji: event.categoryEmoji,
      likeId: event.identifiant,
      infos: [
        if (event.categorie.isNotEmpty)
          _InfoItem(Icons.category_outlined, event.categorie),
        if (event.dateDebut.isNotEmpty)
          _InfoItem(
            Icons.calendar_today,
            event.dateFin.isNotEmpty && event.dateFin != event.dateDebut
                ? '${_formatDate(event.dateDebut)} - ${_formatDate(event.dateFin)}'
                : _formatDate(event.dateDebut),
          ),
        if (event.lieuNom.isNotEmpty)
          _InfoItem(Icons.location_on_outlined, event.lieuNom),
        if (event.horaires.isNotEmpty)
          _InfoItem(Icons.access_time, event.horaires),
        if (event.tarifNormal.isNotEmpty)
          _InfoItem(Icons.euro_outlined, event.tarifNormal),
      ],
      primaryAction: event.reservationUrl.isNotEmpty
          ? _ActionButton(
              icon: Icons.confirmation_number_outlined,
              label: 'Billetterie',
              url: event.reservationUrl,
            )
          : null,
      secondaryActions: [],
      shareText: _buildEventShareText(event),
    );
  }

  Widget _buildPopup({
    required BuildContext context,
    required WidgetRef ref,
    required String image,
    required String title,
    required String emoji,
    required String likeId,
    required List<_InfoItem> infos,
    required _ActionButton? primaryAction,
    required List<_ActionButton> secondaryActions,
    required String shareText,
  }) {
    final isLiked = ref.watch(likesProvider).contains(likeId);
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // ── Pochette en fond ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            _buildGradientFallback(emoji),
                      ),
                    ),
                  ],
                ),

                // ── Gradient overlay ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.55, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenu overlay ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermer
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Emoji
                    if (emoji.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),

                    const Spacer(),

                    // ── Infos en bas ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Titre
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Info rows
                          ...infos.map(
                            (info) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    info.icon,
                                    size: 15,
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      info.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Boutons actions ──
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              // Like
                              _buildPillButton(
                                icon: isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: isLiked ? 'Retirer' : 'Aimer',
                                color: isLiked ? Colors.red : Colors.white,
                                onTap: () {
                                  ref
                                      .read(likesProvider.notifier)
                                      .toggle(likeId);
                                  if (isLiked) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                              // Share
                              _buildPillButton(
                                icon: Icons.share_outlined,
                                label: 'Partager',
                                color: Colors.white,
                                onTap: () => Share.share(shareText),
                              ),
                              // Secondary actions
                              ...secondaryActions.map(
                                (action) => _buildPillButton(
                                  icon: action.icon,
                                  label: action.label,
                                  color: Colors.white,
                                  onTap: () => _openUrl(action.url),
                                ),
                              ),
                            ],
                          ),

                          // Primary action
                          if (primaryAction != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openUrl(primaryAction.url),
                                icon: Icon(primaryAction.icon, size: 18),
                                label: Text(
                                  primaryAction.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientFallback(String emoji) {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
        ),
      ),
      child: emoji.isNotEmpty
          ? Center(
              child: Text(emoji, style: const TextStyle(fontSize: 80)),
            )
          : null,
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _buildCommerceShareText(CommerceModel c) {
    final buffer = StringBuffer();
    buffer.writeln(c.nom);
    if (c.adresse.isNotEmpty) buffer.writeln(c.adresse);
    if (c.horaires.isNotEmpty) buffer.writeln('Horaires: ${c.horaires}');
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  String _buildEventShareText(Event e) {
    final buffer = StringBuffer();
    buffer.writeln(e.titre);
    if (e.dateDebut.isNotEmpty) buffer.writeln('Date: ${e.dateDebut}');
    if (e.lieuNom.isNotEmpty) buffer.writeln('Lieu: ${e.lieuNom}');
    if (e.isFree) buffer.writeln('Gratuit !');
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }
}

class _InfoItem {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);
}

class _ActionButton {
  final IconData icon;
  final String label;
  final String url;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.url,
  });
}
