import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/night/data/closing_hour.dart';

void main() {
  group('closingHour', () {
    test('lit la 2e heure de la plage', () {
      expect(closingHour('18h00 - 02h00'), 2);
      expect(closingHour('23h00 - 06h00'), 6);
      expect(closingHour('17h00 - 01h00'), 1);
    });

    test('tolere les variantes de saisie reelles', () {
      expect(closingHour('16h00 - 02h00 (03h we)'), 2);
      expect(closingHour('18h - 2h'), 2);
      expect(closingHour('18h00 – 02h00'), 2); // tiret demi-cadratin
    });

    test('24h/24 -> 24', () {
      expect(closingHour('Reception 24h/24'), 24);
      expect(closingHour('24h24'), 24);
    });

    test('vide ou illisible -> null', () {
      expect(closingHour(''), null);
      expect(closingHour('   '), null);
      expect(closingHour('Nous consulter'), null);
      expect(closingHour('Th,Fr 13:00-19:00'), null); // format OSM
    });
  });

  group('closesAfter', () {
    test('la fin de nuit compte comme plus tard que la soiree', () {
      // Le piege : 2 (2h du matin) est plus TARD que 23, pas plus tot.
      expect(closesAfter('23h00 - 02h00', 23), isTrue);
      expect(closesAfter('18h00 - 23h00', 2), isFalse);
    });

    test('filtre "ouvert apres 2h"', () {
      expect(closesAfter('23h00 - 06h00', 2), isTrue);
      expect(closesAfter('18h00 - 04h00', 2), isTrue);
      expect(closesAfter('18h00 - 02h00', 2), isTrue); // ferme pile a 2h
      expect(closesAfter('17h00 - 01h00', 2), isFalse);
      expect(closesAfter('18h00 - 00h00', 2), isFalse);
    });

    test('filtre "ouvert apres 6h" (ferme a 7h)', () {
      expect(closesAfter('23h00 - 07h00', 7), isTrue); // Le Purple
      expect(closesAfter('23h00 - 06h00', 7), isFalse); // MAGMA : reste en "apres 2h"
      expect(closesAfter('18h00 - 02h00', 7), isFalse);
    });

    test('24h/24 ressort dans tous les filtres', () {
      expect(closesAfter('Reception 24h/24', 2), isTrue);
      expect(closesAfter('Reception 24h/24', 6), isTrue);
    });

    test('horaires inconnus : jamais dans un filtre', () {
      expect(closesAfter('', 2), isFalse);
      expect(closesAfter('Nous consulter', 2), isFalse);
    });
  });

  group('closesUpTo', () {
    test('filtre "jusqu\'a 2h"', () {
      expect(closesUpTo('19h00 - 02h00', 2), isTrue); // Puerto Habana
      expect(closesUpTo('17h00 - 01h00', 2), isTrue);
      expect(closesUpTo('18h00 - 23h00', 2), isTrue); // ferme avant minuit
      expect(closesUpTo('23h00 - 06h00', 2), isFalse);
      expect(closesUpTo('19h30 - 03h00', 2), isFalse); // La Voile Blanche
    });

    test('24h/24 n\'est jamais "jusqu\'a"', () {
      expect(closesUpTo('Reception 24h/24', 2), isFalse);
      expect(closesUpTo('Reception 24h/24', 7), isFalse);
    });

    test('horaires inconnus : jamais dans un filtre', () {
      expect(closesUpTo('', 2), isFalse);
      expect(closesUpTo('Th,Fr 13:00-19:00', 2), isFalse);
    });

    test('complementaire de closesAfter : aucun lieu dans les deux', () {
      const horaires = [
        '19h00 - 02h00', '23h00 - 06h00', '18h00 - 23h00',
        '17h00 - 01h00', '00h00 - 07h00', 'Reception 24h/24',
      ];
      for (final h in horaires) {
        expect(closesUpTo(h, 2) && closesAfter(h, 3), isFalse,
            reason: '$h ne doit pas etre dans "jusqu\'a 2h" ET "apres 2h"');
      }
    });
  });
}
