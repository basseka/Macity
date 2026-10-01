import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';

void main() {
  group('Confirmation de venue (events prives)', () {
    test('RSVP : confirmed absent (ancienne RPC) -> false', () {
      final r = PrivateEventRsvp.fromJson({
        'user_id': 'u1',
        'prenom': 'Marie',
        'created_at': '2026-10-01T10:00:00Z',
      });
      expect(r.confirmed, isFalse);
    });

    test('RSVP : confirmed renvoye par la RPC', () {
      final r = PrivateEventRsvp.fromJson({
        'user_id': 'u1',
        'created_at': '2026-10-01T10:00:00Z',
        'confirmed': true,
      });
      expect(r.confirmed, isTrue);
    });

    test('Reveal : confirmation_requise lu, false par defaut', () {
      final base = {
        'id': 'e1',
        'title': 'Soiree',
        'date': '2026-10-10',
        'rsvps': <Map<String, dynamic>>[],
      };
      expect(PrivateEventReveal.fromJson(base).confirmationRequise, isFalse);
      expect(
        PrivateEventReveal.fromJson({...base, 'confirmation_requise': true})
            .confirmationRequise,
        isTrue,
      );
    });

    test('Fiche hote : champs, age numerique, date de confirmation', () {
      final c = PrivateEventConfirmation.fromJson({
        'user_id': 'u1',
        'pseudo': 'marie31',
        'nom': 'Durand',
        'prenom': 'Marie',
        'email': 'marie@example.com',
        'age': 27,
        'tel': '+33 6 12 34 56 78',
        'confirmed_at': '2026-10-01T18:30:00Z',
      });
      expect(c.nom, 'Durand');
      expect(c.age, 27);
      expect(c.isConfirmed, isTrue);
      expect(c.confirmedAt!.toUtc().hour, 18);
    });

    test('Fiche vide (jamais confirme) -> non confirmee', () {
      final c = PrivateEventConfirmation.fromJson({
        'nom': null,
        'age': null,
        'confirmed_at': null,
      });
      expect(c.isConfirmed, isFalse);
      expect(c.nom, '');
      expect(c.age, isNull);
    });
  });

  group('Nombre maximum de participants', () {
    // Format de list_my_private_events (to_jsonb + rsvp_count) : timestamps
    // Postgres avec microsecondes et fuseau.
    Map<String, dynamic> hostRow([Map<String, dynamic> extra = const {}]) => {
          'id': 'e1',
          'host_device_uuid': 'h1',
          'title': 'Soiree',
          'date': '2026-10-10',
          'access_token': 't1',
          'passcode': '1234',
          'created_at': '2026-10-01T10:00:00.123456+00:00',
          'updated_at': '2026-10-01T10:00:00.123456+00:00',
          ...extra,
        };

    test('Hote : sans limite -> maxParticipants null, rsvpCount 0', () {
      final e = PrivateEvent.fromJson(hostRow());
      expect(e.maxParticipants, isNull);
      expect(e.rsvpCount, 0);
    });

    test('Hote : limite et nombre d inscrits lus', () {
      final e = PrivateEvent.fromJson(
        hostRow({'max_participants': 20, 'rsvp_count': 12}),
      );
      expect(e.maxParticipants, 20);
      expect(e.rsvpCount, 12);
    });

    test('Invite : max_participants lu', () {
      final r = PrivateEventReveal.fromJson({
        'id': 'e1',
        'title': 'Soiree',
        'date': '2026-10-10',
        'max_participants': 8,
      });
      expect(r.maxParticipants, 8);
    });
  });
}
