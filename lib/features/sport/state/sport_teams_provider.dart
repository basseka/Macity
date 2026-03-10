import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/sport/data/sport_repository.dart';
import 'package:pulz_app/features/sport/domain/models/league.dart';
import 'package:pulz_app/features/sport/domain/models/team.dart';

/// Leagues pour un sport donne.
final sportLeaguesProvider = FutureProvider.family<List<League>, String>(
  (ref, sportName) async {
    final repository = SportRepository();
    return repository.fetchLeagues(sport: sportName);
  },
);

/// Teams d'une ligue donnee.
final leagueTeamsProvider = FutureProvider.family<List<Team>, int>(
  (ref, leagueId) async {
    final repository = SportRepository();
    return repository.fetchTeams(leagueId: leagueId);
  },
);
