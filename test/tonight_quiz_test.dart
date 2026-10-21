import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/tonight_quiz/data/tonight_quiz_service.dart';
import 'package:pulz_app/features/tonight_quiz/domain/tonight_quiz.dart';

void main() {
  const pools = TonightPools(
    night: [
      CommerceModel(nom: 'Cocktail Club', categorie: 'Bar a cocktails'),
      CommerceModel(nom: 'Le Pub', categorie: 'Pub'),
      CommerceModel(nom: 'La Boîte', categorie: 'Club Discotheque'),
      CommerceModel(nom: 'Épicerie', categorie: 'Epicerie de nuit'),
      CommerceModel(nom: 'Coquin', categorie: 'Coquin'),
    ],
    culture: [CommerceModel(nom: 'Théâtre X', categorie: 'Theatre')],
    activities: [
      CommerceModel(nom: 'Escape', categorie: 'Escape game'),
      CommerceModel(nom: 'Piscine', categorie: 'Piscine'),
    ],
    walks: [],
  );
  const events = [
    Event(identifiant: 'a', titre: 'Concert tôt', categorie: 'Concert', horaires: '19h00'),
    Event(identifiant: 'b', titre: 'Concert tard', categorie: 'Concert', horaires: '22h30'),
    Event(identifiant: 'c', titre: 'Pièce', categorie: 'Théâtre', horaires: '21h00'),
  ];
  final at = DateTime(2026, 10, 21, 18, 30);

  test('famille : pas de soirée ni de cocktail proposés', () {
    final w = TonightPools.wishesFor(TonightGroup.famille);
    expect(w, isNot(contains(TonightWish.soiree)));
    expect(w, isNot(contains(TonightWish.cocktail)));
  });

  test('cocktail : bars seulement, jamais épicerie, club ni coquin', () {
    final s = pools.build(
      const TonightAnswers(group: TonightGroup.amis, wishes: {TonightWish.cocktail}, when: TonightWhen.late),
      events,
      now: at,
    );
    final noms = s.single.places.map((c) => c.nom).toSet();
    expect(noms, {'Cocktail Club', 'Le Pub'});
  });

  test('concert tard : garde la séance de 22h30', () {
    final s = pools.build(
      const TonightAnswers(group: TonightGroup.solo, wishes: {TonightWish.concert}, when: TonightWhen.late),
      events,
      now: at,
    );
    expect(s.single.events.map((e) => e.identifiant), ['b']);
    expect(s.single.eventsOtherTime, isFalse);
  });

  test('maintenant : concert de 19h, et repli signalé pour le spectacle', () {
    final s = pools.build(
      const TonightAnswers(
        group: TonightGroup.couple,
        wishes: {TonightWish.concert, TonightWish.spectacle},
        when: TonightWhen.now,
      ),
      events,
      now: at,
    );
    expect(s[0].events.map((e) => e.identifiant), ['a']);
    expect(s[1].events.map((e) => e.identifiant), ['c']);
    expect(s[1].eventsOtherTime, isTrue);
    expect(s[1].places.single.nom, 'Théâtre X');
  });

  test('activité : escape game, pas la piscine', () {
    final s = pools.build(
      const TonightAnswers(group: TonightGroup.amis, wishes: {TonightWish.activite}, when: TonightWhen.afterDinner),
      events,
      now: at,
    );
    expect(s.single.places.map((c) => c.nom), ['Escape']);
  });
}
