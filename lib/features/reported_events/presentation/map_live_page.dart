import 'package:dio/dio.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/presentation/snap_camera_screen.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_carousel.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_legend.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_map.dart';
import 'package:pulz_app/core/widgets/suivi_ecran.dart';

/// Page dediee "Ça bouge près de toi", facon Snap Map : la carte des
/// signalements communautaires occupe tout l'ecran, et tout le reste flotte
/// par-dessus (retour, recherche de ville, Live Notif et legende en haut ;
/// bulles des stories en bas). Ouverte depuis un bouton "Map Live" sur le home.
class MapLivePage extends ConsumerWidget {
  const MapLivePage({super.key});

  /// Hauteur de la bande des stories posee sur le bas de la carte.
  static const _storiesBand = 84.0;

  void _openLiveReport(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SnapCameraScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = MediaQuery.of(context).padding;
    final storiesBottom = pad.bottom + 12;
    return SuiviEcran(
      nom: '/map-live',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      // Carte claire sous la barre d'etat : icones sombres.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1EEE9),
        body: Stack(
          children: [
            // ── Carte bord a bord ──
            Positioned.fill(
              child: ReportedEventsMap(
                height: double.infinity,
                fullscreen: true,
                locateBottom: storiesBottom + _storiesBand + 12,
              ),
            ),

            // ── Haut : degrade discret pour lire les boutons ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: pad.top + 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x55000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: _CitySearchField()),
                      const SizedBox(width: 8),
                      _LiveButton(onTap: () => _openLiveReport(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Legende centree, lisible sur la carte.
                  const Center(
                    child: _GlassChip(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: ReportedEventsLegend(onMap: true),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bas : stories posees sur la carte ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: storiesBottom + _storiesBand + 30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 0,
              bottom: storiesBottom,
              child: const ReportedEventsCarousel(onMap: true),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Bouton rond sombre translucide (retour), comme les commandes Snap Map.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC1C1C22),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Pastille sombre translucide posee sur la carte.
class _GlassChip extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassChip({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xCC1C1C22),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Champ loupe : taper une ville (« Bordeaux ») et valider centre la carte
/// dessus. Villes de l'app : coordonnees locales ; sinon geocodage
/// Nominatim (OSM, sans cle).
class _CitySearchField extends StatefulWidget {
  const _CitySearchField();

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<({double lat, double lng})?> _geocode(String q) async {
    final local = CityCenters.center(q);
    if (local != null) return local;
    try {
      final res = await Dio().get<dynamic>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': '1',
          'accept-language': 'fr',
        },
        options: Options(
          headers: {'User-Agent': 'PulzApp/1.0 (https://macity.app)'},
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final data = res.data;
      if (data is List && data.isNotEmpty && data.first is Map) {
        final m = data.first as Map;
        final lat = double.tryParse('${m['lat']}');
        final lng = double.tryParse('${m['lon']}');
        if (lat != null && lng != null) return (lat: lat, lng: lng);
      }
    } on DioException {
      // Reseau : traite comme « introuvable » ci-dessous.
    }
    return null;
  }

  Future<void> _search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final pos = await _geocode(q);
    if (!mounted) return;
    setState(() => _busy = false);
    if (pos == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(context.l10n.mapCityNotFound(q))),
      );
      return;
    }
    await ReportedEventsMap.flyTo(pos.lat, pos.lng);
  }

  @override
  Widget build(BuildContext context) {
    return _GlassChip(
      padding: const EdgeInsets.only(left: 12, right: 6),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                onSubmitted: _search,
                cursorColor: Colors.white,
                style: GoogleFonts.geist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  // Le theme de l'app remplit les champs (fond blanc) : ici
                  // le texte blanc doit rester sur la pastille sombre.
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: context.l10n.cityPickerHint,
                  hintStyle: GoogleFonts.geist(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else if (_ctrl.text.trim().isNotEmpty)
              // Valider (en plus de la touche loupe du clavier).
              GestureDetector(
                onTap: () => _search(_ctrl.text),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bouton Live Notif compact (camera) : publier une story depuis la carte.
class _LiveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LiveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              'Live',
              style: GoogleFonts.geist(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
