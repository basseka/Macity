import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/domain/night_party_quiz.dart';

void main() {
  // Jeudi 26 novembre 2026.
  final today = DateTime(2026, 11, 26, 18);

  const venues = [
    CommerceModel(
        nom: 'Cocktail Club',
        categorie: 'Bar a cocktails',
        horaires: '18h00 - 01h00'),
    CommerceModel(nom: 'Le Pub', categorie: 'Pub', horaires: '17h00 - 02h00'),
    CommerceModel(
        nom: 'Bar Festif', categorie: 'Bar de nuit', horaires: '18h00 - 02h00'),
    CommerceModel(
        nom: 'Club Électro',
        categorie: 'Club Discotheque',
        horaires: '00h00 - 07h00',
        sourceId: 1),
    CommerceModel(
        nom: 'Club Latino',
        categorie: 'Club Discotheque',
        horaires: '23h00 - 05h00',
        sourceId: 2),
    CommerceModel(nom: 'Le Bikini', categorie: 'Salle de concert'),
    CommerceModel(nom: 'Épicerie', categorie: 'Epicerie de nuit'),
    CommerceModel(nom: 'Hôtel', categorie: 'Hotel'),
    CommerceModel(nom: 'Coquin', categorie: 'Coquin'),
  ];
  const events = [
    Event(
        identifiant: 'a',
        titre: 'Concert rock',
        categorie: 'Concert',
        horaires: '20h00',
        dateDebut: '2026-11-26'),
    Event(
        identifiant: 'b',
        titre: 'Soirée techno',
        categorie: 'Soirée',
        rubrique: 'night',
        horaires: '23h55',
        dateDebut: '2026-11-27'),
    Event(
        identifiant: 'c',
        titre: 'Soirée salsa',
        categorie: 'Soirée',
        rubrique: 'night',
        horaires: '22h00',
        dateDebut: '2026-11-28'),
    Event(
        identifiant: 'd',
        titre: 'After Work',
        categorie: 'Soirée',
        rubrique: 'night',
        horaires: '19h00',
        dateDebut: '2026-11-27'),
  ];
  const quiz = NightPartyQuiz(
    venues: venues,
    events: events,
    clubGenres: {
      1: ['electro'],
      2: ['latino']
    },
  );

  NightPartyAnswers ans(Set<NightVibe> v,
          {NightWhen when = NightWhen.weekend,
          NightLate late = NightLate.allNight,
          Set<NightMusic> music = const {},
          NightGroup group = NightGroup.amis}) =>
      NightPartyAnswers(
          group: group, vibes: v, music: music, when: when, late: late);

  test('week-end un jeudi : vendredi, samedi, dimanche', () {
    final d = NightPartyQuiz.daysFor(NightWhen.weekend, today);
    expect(d.map((x) => x.day).toList()..sort(), [27, 28, 29]);
  });

  test('week-end un samedi : de ce soir à dimanche', () {
    final d = NightPartyQuiz.daysFor(NightWhen.weekend, DateTime(2026, 11, 28));
    expect(d.map((x) => x.day).toList()..sort(), [28, 29]);
  });

  test('jamais épicerie, hôtel ni coquin', () {
    final s = quiz.build(ans(NightVibe.values.toSet()), today: today);
    final names = s.expand((x) => x.places).map((c) => c.nom);
    expect(names, isNot(contains('Épicerie')));
    expect(names, isNot(contains('Hôtel')));
    expect(names, isNot(contains('Coquin')));
  });

  test('un verre au calme : bars à cocktails et pubs, pas de club', () {
    final s = quiz.build(ans({NightVibe.verre}), today: today).single;
    expect(s.places.map((c) => c.nom).toSet(), {'Cocktail Club', 'Le Pub'});
  });

  test('danser + latino : le club latino passe devant', () {
    for (var seed = 0; seed < 10; seed++) {
      final s = quiz
          .build(ans({NightVibe.danser}, music: {NightMusic.latino}),
              today: today, seed: seed)
          .single;
      expect(s.places.first.nom, 'Club Latino');
    }
  });

  test('danser : soirées dansantes de la période seulement', () {
    final s = quiz.build(ans({NightVibe.danser}), today: today).single;
    expect(s.events.map((e) => e.identifiant).toSet(), {'b', 'c'});
  });

  test('ce soir : seulement les events du jour', () {
    final s = quiz
        .build(ans({NightVibe.concert}, when: NightWhen.tonight), today: today)
        .single;
    expect(s.events.map((e) => e.identifiant), ['a']);
    expect(s.places.map((c) => c.nom), ['Le Bikini']);
  });

  test('soirée à thème : soirées non dansantes', () {
    final s = quiz.build(ans({NightVibe.theme}), today: today).single;
    expect(s.events.map((e) => e.identifiant), ['d']);
  });

  test('pas trop tard : le bar qui ferme à 1 h passe devant les autres', () {
    for (var seed = 0; seed < 10; seed++) {
      final s = quiz
          .build(ans({NightVibe.verre}, late: NightLate.early),
              today: today, seed: seed)
          .single;
      expect(s.places.first.nom, 'Cocktail Club');
    }
  });

  test('un lieu ne revient pas dans deux sections', () {
    final s = quiz.build(ans(NightVibe.values.toSet()), today: today);
    final names = s.expand((x) => x.places).map((c) => c.nom).toList();
    expect(names.length, names.toSet().length);
  });

  test('la question musique ne vient que pour danser, concert ou thème', () {
    expect(
        NightPartyAnswers.asksMusic({NightVibe.verre, NightVibe.bar}), isFalse);
    expect(NightPartyAnswers.asksMusic({NightVibe.verre, NightVibe.danser}),
        isTrue);
  });

  test('toutes les soirées du week-end : triées par jour puis par heure', () {
    final l = quiz.eventsInPeriod(NightWhen.weekend, today);
    expect(l.map((e) => e.identifiant), ['d', 'b', 'c']);
    expect(
        quiz.eventsInPeriod(NightWhen.tonight, today).map((e) => e.identifiant),
        ['a']);
  });
}
