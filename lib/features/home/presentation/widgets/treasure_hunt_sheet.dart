import 'dart:math';

import 'package:flutter/material.dart';

class _Enigma {
  final String riddle;
  final String hint;
  final String answer;
  final String location;

  const _Enigma({
    required this.riddle,
    required this.hint,
    required this.answer,
    required this.location,
  });
}

const _enigmas = [
  _Enigma(
    riddle:
        'Je suis rose comme l\'aurore, des milliers me traversent chaque jour.\n'
        'Je relie deux rives sans jamais me mouiller les pieds.\n'
        'Les amoureux s\'y arretent, les touristes m\'admirent.\n'
        'Qui suis-je ?',
    hint: 'Je suis le plus vieux pont de la ville...',
    answer: 'Le Pont Neuf',
    location: 'Pont Neuf, Toulouse',
  ),
  _Enigma(
    riddle:
        'Place majestueuse, je porte le nom d\'un edifice de Rome.\n'
        'Ma croix occitane trone en mon centre.\n'
        'On s\'y retrouve pour celebrer, manifester ou simplement flaner.\n'
        'Qui suis-je ?',
    hint: 'Mon nom evoque un batiment antique italien...',
    answer: 'La Place du Capitole',
    location: 'Place du Capitole, Toulouse',
  ),
  _Enigma(
    riddle:
        'Basilique de briques, je suis l\'une des plus grandes romanes d\'Europe.\n'
        'Les pelerins de Compostelle font halte chez moi.\n'
        'Mon nom evoque la saturation, le trop-plein.\n'
        'Qui suis-je ?',
    hint: 'Mon nom vient du latin "serninus"... ou pas !',
    answer: 'La Basilique Saint-Sernin',
    location: 'Basilique Saint-Sernin, Toulouse',
  ),
  _Enigma(
    riddle:
        'Je suis un canal qui traverse la ville rose,\n'
        'classe au patrimoine mondial, borde de platanes.\n'
        'On s\'y promene a pied, a velo ou en bateau.\n'
        'Pierre-Paul Riquet m\'a imagine.\n'
        'Qui suis-je ?',
    hint: 'Je relie l\'Atlantique a la Mediterranee...',
    answer: 'Le Canal du Midi',
    location: 'Canal du Midi, Toulouse',
  ),
  _Enigma(
    riddle:
        'Je suis un couvent devenu musee,\n'
        'les Jacobins m\'ont bati avec devotion.\n'
        'Mon palmier de pierre est celebre dans le monde entier.\n'
        'Qui suis-je ?',
    hint: 'Thomas d\'Aquin repose entre mes murs...',
    answer: 'Le Couvent des Jacobins',
    location: 'Couvent des Jacobins, Toulouse',
  ),
  _Enigma(
    riddle:
        'Fleuve majestueux, je traverse la ville en serpentant.\n'
        'Mes berges accueillent joggers et reveurs.\n'
        'Mon nom commence comme un prenom feminin.\n'
        'Qui suis-je ?',
    hint: 'Je prends ma source dans les Pyrenees...',
    answer: 'La Garonne',
    location: 'Berges de la Garonne, Toulouse',
  ),
  _Enigma(
    riddle:
        'Cite de l\'espace et des etoiles,\n'
        'je fais rever petits et grands.\n'
        'Une replique grandeur nature d\'Ariane 5 trone a mon entree.\n'
        'Qui suis-je ?',
    hint: 'Je suis un parc a theme dedie au cosmos...',
    answer: 'La Cite de l\'Espace',
    location: 'Cite de l\'Espace, Toulouse',
  ),
];

class TreasureHuntSheet extends StatefulWidget {
  const TreasureHuntSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TreasureHuntSheet(),
    );
  }

  @override
  State<TreasureHuntSheet> createState() => _TreasureHuntSheetState();
}

class _TreasureHuntSheetState extends State<TreasureHuntSheet>
    with SingleTickerProviderStateMixin {
  late final _Enigma _enigma;
  bool _hintRevealed = false;
  bool _answerRevealed = false;
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _enigma = _enigmas[Random().nextInt(_enigmas.length)];
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          AnimatedBuilder(
            animation: _sparkle,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.4 + _sparkle.value * 0.6,
                    child: const Text(
                      '\u{2728}',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chasse au Tresor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E342E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: 0.4 + (1 - _sparkle.value) * 0.6,
                    child: const Text(
                      '\u{2728}',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),
          const Text(
            'Trouve la cachette du tresor !',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Color(0xFF795548),
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Treasure chest icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('\u{1F381}', style: TextStyle(fontSize: 34)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Enigma card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Text(
                              '\u{1F50D}',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Enigme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4E342E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _enigma.riddle,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hint button / reveal
                  if (!_hintRevealed)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _hintRevealed = true),
                        icon: const Text(
                          '\u{1F4A1}',
                          style: TextStyle(fontSize: 16),
                        ),
                        label: const Text('Voir l\'indice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                          side: const BorderSide(color: Color(0xFFFFB300)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFCC80),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '\u{1F4A1}',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _enigma.hint,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Answer button / reveal
                  if (!_answerRevealed)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _answerRevealed = true),
                        icon: const Text(
                          '\u{1F513}',
                          style: TextStyle(fontSize: 16),
                        ),
                        label: const Text(
                          'Reveler la cachette',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '\u{1F389}',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _enigma.answer,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF4E342E),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _enigma.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4E342E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
