import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/guest_list_pdf.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  PrivateEvent event({bool confirmation = true}) => PrivateEvent.fromJson({
        'id': 'e1',
        'host_device_uuid': 'h1',
        'title': "Soirée d'anniversaire de Zoé 🎉 chez Œdipe — édition très spéciale",
        'date': '2026-10-10',
        'heure': '21h',
        'lieu': 'Chez moi, Toulouse',
        'access_token': 't1',
        'passcode': '1234',
        'confirmation_requise': confirmation,
        'max_participants': 20,
        'created_at': '2026-10-01T10:00:00Z',
        'updated_at': '2026-10-01T10:00:00Z',
      });

  final rsvps = [
    for (var i = 0; i < 30; i++)
      PrivateEventRsvp(
        userId: 'u$i',
        prenom: i == 0 ? 'Zoé 💃' : 'Invité n°$i',
        createdAt: DateTime.utc(2026, 10, 1, 12, i),
        confirmed: i < 12,
      ),
  ];
  final confirmations = [
    for (var i = 0; i < 12; i++)
      PrivateEventConfirmation(
        userId: 'u$i',
        pseudo: i == 0 ? 'Zoé 💃' : 'Invité n°$i',
        nom: i == 0 ? "D'Arcy-Lefèvre" : 'Durand',
        prenom: i == 0 ? 'Zoé' : 'Jérôme',
        email: 'invite$i@example.com',
        age: 20 + i,
        tel: '+33 6 12 34 56 ${(10 + i).toString().padLeft(2, '0')}',
        confirmedAt: DateTime.utc(2026, 10, 1, 18, i),
      ),
  ];

  test('PDF avec confirmations : genere, accents et emojis sans erreur', () async {
    final bytes = await GuestListPdf.buildBytes(
      event: event(),
      rsvps: rsvps,
      confirmations: confirmations,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
    // Copie pour inspection visuelle eventuelle.
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('PDF sans confirmation (liste simple) et liste vide', () async {
    final a = await GuestListPdf.buildBytes(
      event: event(confirmation: false),
      rsvps: rsvps,
      confirmations: const [],
    );
    final b = await GuestListPdf.buildBytes(
      event: event(confirmation: false),
      rsvps: const [],
      confirmations: const [],
    );
    expect(String.fromCharCodes(a.take(4)), '%PDF');
    expect(String.fromCharCodes(b.take(4)), '%PDF');
  });
}
