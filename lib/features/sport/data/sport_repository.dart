import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/data/football_api_service.dart';
import 'package:pulz_app/features/sport/data/espn_rugby_api_service.dart';
import 'package:pulz_app/features/sport/data/gala_boxe_scraper.dart';
import 'package:pulz_app/features/sport/data/team_configs/football_team_config.dart';
import 'package:pulz_app/features/sport/data/team_configs/rugby_team_config.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/domain/models/football_match.dart';
import 'package:pulz_app/features/sport/domain/models/espn_rugby_event.dart';

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
  /// "Cette Semaine" → all sports for the current week.
  /// Other sports → filter by sport name (scraper data = home matches only).
  Future<List<SupabaseMatch>> fetchSupabaseMatches({
    String? sport,
    String? ville,
  }) async {
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    // "Cette Semaine" → all sports for the current week
    if (sport == 'Cette Semaine') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final results = await Future.wait([
        _supabaseApi.fetchMatches(
          ville: ville,
          dateGte: _formatDate(weekStart),
          dateLt: _formatDate(weekEnd),
        ),
        GalaBoxeScraper.fetchUpcomingEvents(),
      ]);
      final supabaseMatches = results[0];
      final boxeMatches = results[1].where((m) {
        final d = DateTime.tryParse(m.date);
        return d != null && !d.isBefore(weekStart) && d.isBefore(weekEnd);
      });
      return [...supabaseMatches, ...boxeMatches];
    }

    // Boxe → Supabase + scraper galadeboxetoulouse.com
    if (sport != null && sport.toLowerCase() == 'boxe') {
      final results = await Future.wait([
        _supabaseApi.fetchMatches(sport: sport, ville: ville, dateGte: dateStr),
        GalaBoxeScraper.fetchUpcomingEvents(),
      ]);
      return [...results[0], ...results[1]];
    }

    // All other sports → query Supabase table (populated by scrapers)
    return _supabaseApi.fetchMatches(
      sport: sport,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
