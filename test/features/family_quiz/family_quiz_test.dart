import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';
import 'package:pulz_app/features/family_quiz/domain/family_quiz.dart';

void main() {
  // Mercredi 25/11/2026.
  final wed = DateTime(2026, 11, 25, 10);

  test('week-end : samedi-dimanche suivants, ou celui en cours', () {
    expect(FamilyQuizEngine.period(FamilyWhen.weekend, wed),
        (DateTime(2026, 11, 28), DateTime(2026, 11, 29)));
    expect(FamilyQuizEngine.period(FamilyWhen.weekend, DateTime(2026, 11, 29)),
        (DateTime(2026, 11, 29), DateTime(2026, 11, 29)));
  });

  test('âge lu dans le texte des events', () {
    expect(FamilyQuizEngine.eventMinAge(
        const Event(titre: 'Atelier', descriptifCourt: 'Âge : 8 ans-Et plus.')), 8);
    expect(FamilyQuizEngine.eventMinAge(
        const Event(titre: 'Conte dès 3 ans')), 3);
    expect(FamilyQuizEngine.eventMinAge(const Event(titre: 'Spectacle')), null);
  });

  test('filtres âge, dedans/dehors, période et envies', () {
    const venues = [
      FamilyVenue(id: 1, slug: 'a', name: 'Laser', category: 'Laser game'),
      FamilyVenue(id: 2, slug: 'b', name: 'Aire', category: 'Aire de jeux'),
      FamilyVenue(id: 3, slug: 'c', name: 'Bowling', category: 'Bowling', ageMin: 8),
      FamilyVenue(id: 4, slug: 'd', name: 'Musée', category: 'Musee pour enfants'),
    ];
    const events = [
      Event(identifiant: 'e1', titre: 'Spectacle de marionnettes',
          dateDebut: '2026-11-28', dateFin: '2026-11-28'),
      Event(identifiant: 'e2', titre: 'Cirque dès 8 ans',
          dateDebut: '2026-11-29', dateFin: '2026-11-29'),
      Event(identifiant: 'e3', titre: 'Théâtre', dateDebut: '2026-12-10'),
    ];
    final r = FamilyQuizEngine().build(
      const FamilyAnswers(
        ages: {FamilyAge.baby, FamilyAge.kids},
        wishes: {FamilyWish.move, FamilyWish.show},
        where: FamilyWhere.any,
        when: FamilyWhen.weekend,
      ),
      venues: venues,
      events: events,
      now: wed,
    );
    final move = r.firstWhere((s) => s.wish == FamilyWish.move);
    // Laser exclu (bébé), bowling exclu (dès 8 ans) : reste l'aire de jeux.
    expect(move.places.map((v) => v.id), [2]);
    final show = r.firstWhere((s) => s.wish == FamilyWish.show);
    // e2 dès 8 ans exclu, e3 hors week-end.
    expect(show.events.map((e) => e.identifiant), ['e1']);

    final indoor = FamilyQuizEngine().build(
      const FamilyAnswers(
        ages: {FamilyAge.teens},
        wishes: {FamilyWish.move},
        where: FamilyWhere.indoor,
        when: FamilyWhen.week,
      ),
      venues: venues,
      events: const [],
      now: wed,
    );
    // Ados en intérieur : laser + bowling, pas l'aire de jeux.
    expect(indoor.first.places.map((v) => v.id).toSet(), {1, 3});
  });
}
