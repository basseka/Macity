import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/features/offers/presentation/subscription_screen.dart';

/// Vidéo de présentation jouée au tap sur une offre verrouillée, suivie de la
/// proposition d'abonnement.
///
/// L'URL vient de `app_config.teaser_video_url`, modifiable sans release.
/// **Si elle est vide ou si la lecture échoue, on va droit à l'abonnement** :
/// une vidéo manquante ne doit jamais bloquer le parcours — l'utilisateur a
/// manifesté un intérêt, on ne le laisse pas devant un écran noir.
///
/// La vidéo est passable : forcer un visionnage complet agace plus qu'il ne
/// convainc, et un utilisateur qui veut s'abonner tout de suite doit pouvoir.
class TeaserVideoScreen extends StatefulWidget {
  final String videoUrl;
  const TeaserVideoScreen({super.key, required this.videoUrl});

  /// Point d'entrée unique : gère le cas « pas de vidéo » sans que l'appelant
  /// ait à s'en soucier.
  static Future<void> ouvrir(BuildContext context, {required String videoUrl}) {
    if (videoUrl.trim().isEmpty) {
      return Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TeaserVideoScreen(videoUrl: videoUrl)),
    );
  }

  @override
  State<TeaserVideoScreen> createState() => _TeaserVideoScreenState();
}

class _TeaserVideoScreenState extends State<TeaserVideoScreen> {
  VideoPlayerController? _c;
  bool _erreur = false;
  bool _termine = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _c = c;
    c.addListener(_onTick);
    c.initialize().then((_) {
      if (!mounted) return;
      c.play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _erreur = true);
    });
  }

  void _onTick() {
    final c = _c;
    if (c == null || !c.value.isInitialized || _termine) return;
    final fini = c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero;
    if (fini) {
      _termine = true;
      _versAbonnement();
    }
  }

  /// Remplace l'écran vidéo au lieu de l'empiler : revenir en arrière depuis
  /// l'abonnement doit ramener aux offres, pas rejouer la vidéo.
  void _versAbonnement() {
    if (!mounted) return;
    _c?.pause();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final pret = c != null && c.value.isInitialized && !_erreur;

    // Erreur de lecture : on n'affiche pas de message d'échec, on enchaîne.
    if (_erreur) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _versAbonnement());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (pret)
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            ),

          // Progression : l'utilisateur voit combien il reste, plutôt que de
          // subir une attente aveugle.
          if (pret)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: false,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFE91E63),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: TextButton(
              onPressed: _versAbonnement,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Passer', style: TextStyle(fontSize: 13)),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
