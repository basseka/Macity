import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/data/football_api_service.dart';
import 'package:pulz_app/features/sport/data/espn_rugby_api_service.dart';
import 'package:pulz_app/features/sport/data/team_configs/football_team_config.dart';
import 'package:pulz_app/features/sport/data/team_configs/rugby_team_config.dart';
import 'package:pulz_app/features/sport/domain/models/league.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/domain/models/football_match.dart';
import 'package:pulz_app/features/sport/domain/models/espn_rugby_event.dart';
import 'package:pulz_app/features/sport/domain/models/team.dart';

class SportRepository {
  final SupabaseApiService _supabaseApi;
  final FootballApiService _footballApi;
  final EspnRugbyApiService _espnApi;

  SportRepository({
    SupabaseApiService? supabaseApi,
    FootballApiService? footballApi,
    EspnRugbyApiService? espnApi,
  })  : _supabaseApi = supabaseApi ?? SupabaseApiService(),
        _footballApi = footballApi ?? FootballApiService(),
        _espnApi = espnApi ?? EspnRugbyApiService();

  /// Fetch matches from Supabase (populated by scrapers via cron job).
  ///
  /// "A venir" → all upcoming sports (no time limit).
  /// Other sports → filter by sport name (scraper data = home matches only).
  Future<List<SupabaseMatch>> fetchSupabaseMatches({
    String? sport,
    String? ville,
  }) async {
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    // All sports (including boxe) are now in the matchs table,
    // populated by server-side scrapers (Edge Functions + pg_cron).
    return _supabaseApi.fetchMatches(
      sport: sport == 'A venir' ? null : sport,
      ville: ville,
      dateGte: dateStr,
    );
  }

  /// Fetch football matches for a city
  Future<List<FootballMatch>> fetchFootballMatches(String city) async {
    final teams = FootballTeamConfigs.teams.where((t) => t.name.toLowerCase().contains(city.toLowerCase())).toList();
    final allMatches = <FootballMatch>[];

    for (final team in teams) {
      try {
        final now = DateTime.now();
        final dateFrom = _formatDate(now);
        final dateTo = _formatDate(now.add(const Duration(days: 90)));

        final matches = await _footballApi.fetchTeamMatches(
          teamId: team.teamId,
          dateFrom: dateFrom,
          dateTo: dateTo,
          status: 'SCHEDULED',
        );
        allMatches.addAll(matches);
      } catch (_) {
        // Skip failed teams
      }
    }

    return allMatches;
  }

  /// Fetch rugby events for Top 14
  Future<List<EspnRugbyEvent>> fetchRugbyEvents() async {
    return _espnApi.fetchLeagueEvents(
      leagueId: RugbyTeamConfigs.espnTop14LeagueId,
    );
  }

  /// Fetch rugby events for a specific team
  Future<List<EspnRugbyEvent>> fetchTeamRugbyEvents(int teamId) async {
    if (teamId == 0) return [];
    return _espnApi.fetchTeamEvents(teamId: teamId);
  }

  /// Fetch leagues for a sport (e.g. 'rugby' → Top 14, Pro D2).
  Future<List<League>> fetchLeagues({required String sport}) {
    return _supabaseApi.fetchLeagues(sport: sport);
  }

  /// Fetch teams, optionally filtered by league.
  Future<List<Team>> fetchTeams({int? leagueId}) {
    return _supabaseApi.fetchTeams(leagueId: leagueId);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
