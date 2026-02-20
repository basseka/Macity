import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdBannerMarquee extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const AdBannerMarquee({
    super.key,
    this.backgroundColor = const Color(0xFF4A1259),
    this.textColor = Colors.white,
    this.height = 44,
  });

  @override
  State<AdBannerMarquee> createState() => _AdBannerMarqueeState();
}

class _AdBannerMarqueeState extends State<AdBannerMarquee>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    _ToulouseInfo(
      icon: Icons.directions_bus_rounded,
      text: 'Tisseo - Infos trafic et horaires en temps reel',
      url: 'https://www.tisseo.fr',
    ),
    _ToulouseInfo(
      icon: Icons.water_drop_rounded,
      text: 'Qualite de l\'air a Toulouse - Consultez les indices',
      url: 'https://www.atmo-occitanie.org',
    ),
    _ToulouseInfo(
      icon: Icons.recycling_rounded,
      text: 'Collecte des dechets - Calendrier et points de tri',
      url: 'https://www.toulouse-metropole.fr/dechets',
    ),
    _ToulouseInfo(
      icon: Icons.park_rounded,
      text: 'Parcs et jardins de Toulouse Metropole - Decouvrez les espaces verts',
      url: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
    ),
    _ToulouseInfo(
      icon: Icons.pool_rounded,
      text: 'Piscines et equipements sportifs - Horaires et acces',
      url: 'https://www.toulouse.fr/web/sports/piscines',
    ),
    _ToulouseInfo(
      icon: Icons.menu_book_rounded,
      text: 'Bibliotheques de Toulouse - Emprunts, animations et ateliers',
      url: 'https://www.bibliotheque.toulouse.fr',
    ),
    _ToulouseInfo(
      icon: Icons.pedal_bike_rounded,
      text: 'VeloToulouse - Stations et disponibilites en temps reel',
      url: 'https://www.velotoulouse.com',
    ),
    _ToulouseInfo(
      icon: Icons.account_balance_rounded,
      text: 'Demarches administratives - Etat civil, urbanisme, elections',
      url: 'https://www.toulouse-metropole.fr',
    ),
  ];

  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });

    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
        _restartScrolling();
      }
    });
  }

  void _startScrolling() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _animationController.value * maxScroll,
        );
      }
    });

    _animationController.repeat();
  }

  void _restartScrolling() {
    _animationController.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _animationController.repeat();
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _messages[_currentIndex];

    return GestureDetector(
      onTap: () => _openUrl(info.url),
      child: Container(
        height: widget.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A1259), Color(0xFF7B2D8E)],
          ),
        ),
        child: Row(
          children: [
            // Toulouse Metropole badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: widget.height,
              decoration: const BoxDecoration(
                color: Color(0xFF3A0E47),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_city_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'TM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Scrolling info
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: SingleChildScrollView(
                  key: ValueKey(_currentIndex),
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          info.icon,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          info.text,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // "+" button — same style as TM badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: widget.height,
              decoration: const BoxDecoration(
                color: Color(0xFF3A0E47),
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToulouseInfo {
  final IconData icon;
  final String text;
  final String url;

  const _ToulouseInfo({
    required this.icon,
    required this.text,
    required this.url,
  });
}
