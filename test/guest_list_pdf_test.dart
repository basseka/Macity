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
      confirmations: confirmations,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
    // Copie pour inspection visuelle eventuelle.
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('PDF sans aucune confirmation', () async {
    final bytes = await GuestListPdf.buildBytes(
      event: event(),
      confirmations: const [],
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
