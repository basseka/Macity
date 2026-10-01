import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';

void main() {
  group('Album et souvenirs (events prives)', () {
    test('Photo : champs lus, legende et auteur optionnels', () {
      final p = PrivateEventPhoto.fromJson({
        'id': 'm1',
        'image_url': 'https://x/private_chat/a.jpg',
        'caption': null,
        'user_id': 'u1',
        'prenom': null,
        'is_host': true,
        'created_at': '2026-10-10T22:15:00.123456+00:00',
      });
      expect(p.caption, '');
      expect(p.prenom, isNull);
      expect(p.isHost, isTrue);
      expect(p.createdAt.toUtc().hour, 22);
    });

    test('Souvenir : compteurs, apercu et archivage', () {
      final m = PrivateEventMemory.fromJson({
        'id': 'e1',
        'access_token': 't1',
        'title': 'Soiree',
        'photo_url': null,
        'date': '2026-09-20',
        'heure': '21h',
        'lieu': 'Chez moi',
        'is_host': false,
        'archived': true,
        'participants': 12,
        'photo_count': 37,
        'preview': ['a', 'b', 'c', 'd'],
      });
      expect(m.archived, isTrue);
      expect(m.participants, 12);
      expect(m.photoCount, 37);
      expect(m.preview, hasLength(4));
      expect(m.isHost, isFalse);
    });

    test('Souvenir sans photo : apercu vide, valeurs par defaut', () {
      final m = PrivateEventMemory.fromJson({
        'id': 'e2',
        'access_token': 't2',
        'title': 'Apero',
        'date': '2026-09-30',
        'preview': [],
      });
      expect(m.preview, isEmpty);
      expect(m.photoCount, 0);
      expect(m.archived, isFalse);
    });
  });
}
