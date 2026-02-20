class ApiConstants {
  ApiConstants._();

  // Sirene (INSEE)
  static const String sireneBaseUrl = 'https://api.insee.fr/';
  static const String sireneEndpoint = 'entreprises/sirene/V3.11/siret';
  static const String sireneTokenUrl = 'https://api.insee.fr/token';

  // Overpass (OpenStreetMap)
  static const String overpassBaseUrl = 'https://overpass-api.de/api/';
  static const String overpassFallbackBaseUrl = 'https://overpass.kumi.systems/api/';
  static const String overpassEndpoint = 'interpreter';

  // Backend
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000/',
  );
  static const String backendIosBaseUrl = String.fromEnvironment(
    'BACKEND_IOS_URL',
    defaultValue: 'http://localhost:3000/',
  );

  // Toulouse OpenData
  static const String toulouseBaseUrl = 'https://data.toulouse-metropole.fr/';
  static const String toulouseEventsEndpoint =
      'api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records';

  // Geo.gouv.fr
  static const String geoBaseUrl = 'https://geo.api.gouv.fr/';
  static const String geoCommunesEndpoint = 'communes';

  // OpenAgenda (OpenDataSoft)
  static const String openAgendaBaseUrl = 'https://public.opendatasoft.com/';

  // Football Data
  static const String footballBaseUrl = 'https://api.football-data.org/';
  static const String footballApiToken = String.fromEnvironment('FOOTBALL_API_TOKEN');

  // ESPN
  static const String espnBaseUrl = 'https://site.api.espn.com/';

  // Supabase REST
  static const String supabaseRestUrl = String.fromEnvironment(
    'SUPABASE_REST_URL',
    defaultValue: 'https://dpqxefmwjfvoysacwgef.supabase.co/rest/v1/',
  );

  // Ticketmaster Discovery v2
  static const String ticketmasterBaseUrl = 'https://app.ticketmaster.com/';
  static const String ticketmasterEventsEndpoint = 'discovery/v2/events.json';
  static const String ticketmasterApiKey = String.fromEnvironment('TICKETMASTER_API_KEY');

  // Festik (billetterie festivals)
  static const String festikBaseUrl = 'https://billetterie.festik.net/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
