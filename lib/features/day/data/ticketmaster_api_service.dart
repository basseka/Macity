import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Client pour l'API Ticketmaster Discovery v2.
///
/// Recherche les evenements musicaux a Toulouse et convertit
/// la reponse JSON Ticketmaster en objets [Event] unifies.
class TicketmasterApiService {
  final Dio _dio;

  TicketmasterApiService({Dio? dio})
      : _dio = dio ??
            DioClient.withBaseUrl(ApiConstants.ticketmasterBaseUrl);

  /// Recupere les concerts a Toulouse via Ticketmaster Discovery.
  Future<List<Event>> fetchConcertsToulouse({int size = 50}) async {
    try {
      final response = await _dio.get(
        ApiConstants.ticketmasterEventsEndpoint,
        queryParameters: {
          'apikey': ApiConstants.ticketmasterApiKey,
          'city': 'Toulouse',
          'countryCode': 'FR',
          'classificationName': 'Music',
          'sort': 'date,asc',
          'size': size,
        },
      );

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      if (embedded == null) return [];

      final events = embedded['events'] as List? ?? [];
      return events
          .map((e) => _parseEvent(e as Map<String, dynamic>))
          .where((e) => e != null)
          .cast<Event>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Convertit un objet JSON Ticketmaster en [Event].
  Event? _parseEvent(Map<String, dynamic> json) {
    try {
      final name = json['name'] as String? ?? '';
      final id = json['id'] as String? ?? '';

      // Date
      final dates = json['dates'] as Map<String, dynamic>?;
      final start = dates?['start'] as Map<String, dynamic>?;
      final localDate = start?['localDate'] as String? ?? '';
      final localTime = start?['localTime'] as String? ?? '';

      // Lieu
      final embedded = json['_embedded'] as Map<String, dynamic>?;
      final venues = embedded?['venues'] as List?;
      final venue = venues?.isNotEmpty == true
          ? venues!.first as Map<String, dynamic>
          : <String, dynamic>{};
      final venueName = venue['name'] as String? ?? '';
      final venueCity = venue['city']?['name'] as String? ?? 'Toulouse';
      final venueAddress =
          venue['address']?['line1'] as String? ?? '';

      // Image (prendre la plus grande)
      final images = json['images'] as List? ?? [];
      String? imageUrl;
      if (images.isNotEmpty) {
        // Trier par largeur decroissante pour avoir la meilleure qualite
        final sorted = List<Map<String, dynamic>>.from(
            images.cast<Map<String, dynamic>>(),);
        sorted.sort((a, b) =>
            (b['width'] as int? ?? 0).compareTo(a['width'] as int? ?? 0),);
        imageUrl = sorted.first['url'] as String?;
      }

      // Billetterie
      final ticketUrl = json['url'] as String? ?? '';

      // Prix
      final priceRanges = json['priceRanges'] as List?;
      String tarif = '';
      if (priceRanges != null && priceRanges.isNotEmpty) {
        final pr = priceRanges.first as Map<String, dynamic>;
        final min = pr['min'];
        final max = pr['max'];
        final currency = pr['currency'] as String? ?? 'EUR';
        if (min != null && max != null) {
          tarif = '${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}$currency';
        } else if (min != null) {
          tarif = 'A partir de ${min.toStringAsFixed(0)}$currency';
        }
      }

      // Horaires formatees
      String horaires = '';
      if (localTime.isNotEmpty) {
        final parts = localTime.split(':');
        if (parts.length >= 2) {
          horaires = '${parts[0]}h${parts[1]}';
        }
      }

      return Event(
        identifiant: 'tm_$id',
        titre: name,
        dateDebut: localDate,
        horaires: horaires,
        lieuNom: venueName,
        lieuAdresse: venueAddress,
        commune: venueCity,
        categorie: 'Concert',
        type: 'Concert',
        manifestationGratuite: 'non',
        tarifNormal: tarif,
        reservationUrl: ticketUrl,
        photoPath: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
