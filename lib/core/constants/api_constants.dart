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

  // Backend (local)
  static const String backendBaseUrl = 'http://10.0.2.2:3000/';
  static const String backendIosBaseUrl = 'http://localhost:3000/';

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
  static const String footballApiToken = '568af3e5714f491aaa2f700bcb0c3f54';

  // ESPN
  static const String espnBaseUrl = 'https://site.api.espn.com/';

  // Supabase REST
  static const String supabaseRestUrl =
      'https://dpqxefmwjfvoysacwgef.supabase.co/rest/v1/';

  // Ticketmaster Discovery v2
  static const String ticketmasterBaseUrl = 'https://app.ticketmaster.com/';
  static const String ticketmasterEventsEndpoint = 'discovery/v2/events.json';
  static const String ticketmasterApiKey = 'FZihyhGkVrpCwZmTyz0SEUA9SD1ifi4r';

  // Festik (billetterie festivals)
  static const String festikBaseUrl = 'https://billetterie.festik.net/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
