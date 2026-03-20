import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Unified search result wrapping events, matches and venues from all sources.
sealed class SearchResult {
  /// Relevance score: 0 = title match, 1 = lieu/description, 2 = category/tag.
  final int relevance;

  /// Date string (yyyy-MM-dd) for sorting.
  final String date;

  const SearchResult({required this.relevance, required this.date});

  /// Unique key for deduplication (type + id).
  String get deduplicationKey;
}

class EventResult extends SearchResult {
  final Event event;

  const EventResult({
    required this.event,
    required super.relevance,
    required super.date,
  });

  @override
  String get deduplicationKey => 'event_${event.identifiant}';
}

class MatchResult extends SearchResult {
  final SupabaseMatch match;

  const MatchResult({
    required this.match,
    required super.relevance,
    required super.date,
  });

  @override
  String get deduplicationKey => 'match_${match.id}';
}

/// Resultat de recherche pour un lieu/commerce (restaurant, bar, etc.).
class VenueResult extends SearchResult {
  final String id;
  final String name;
  final String categorie;
  final String adresse;
  final String horaires;
  final String telephone;
  final String? photo;
  final String? siteWeb;
  final String? lienMaps;

  const VenueResult({
    required this.id,
    required this.name,
    required this.categorie,
    required this.adresse,
    this.horaires = '',
    this.telephone = '',
    this.photo,
    this.siteWeb,
    this.lienMaps,
    required super.relevance,
  }) : super(date: '9999-12-31'); // Venues n'ont pas de date, affichees apres les events

  @override
  String get deduplicationKey => 'venue_$id';
}
