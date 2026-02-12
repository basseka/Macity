import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service qui recupere les evenements depuis billetterie.festik.net
/// en parsant les donnees JSON-LD (schema.org) embarquees dans le HTML.
///
/// Filtre les evenements par ville (Toulouse et agglomeration).
class FestikApiService {
  final Dio _dio;

  FestikApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'text/html',
                  'User-Agent': 'PulzApp/1.0',
                },
              ),
            );

  static const _baseUrl = 'https://billetterie.festik.net/';

  /// Villes de l'agglomeration toulousaine acceptees.
  static const _toulouseCities = {
    'toulouse',
    'ramonville',
    'ramonville-saint-agne',
    'balma',
    'colomiers',
    'blagnac',
    'tournefeuille',
    'labege',
    'castanet-tolosan',
    'saint-orens-de-gameville',
    'saint-orens',
    'l\'union',
    'aucamville',
    'fenouillet',
    'cugnaux',
    'portet-sur-garonne',
    'muret',
    'plaisance-du-touch',
    'plaisance du touch',
    'bruguieres',
    'cornebarrieu',
    'pibrac',
    'villeneuve-tolosane',
    'villeneuve tolosane',
    'paulhac',
    'saint-alban',
  };

  /// Recupere les evenements Festik pour Toulouse et agglomeration.
  ///
  /// [categorie] permet de tagger les evenements retournes (ex: 'Concert',
  /// 'Festival'). Par defaut 'Festival'.
  Future<List<Event>> fetchToulouseEvents({
    String categorie = 'Festival',
  }) async {
    try {
      final response = await _dio.get(_baseUrl);
      if (response.statusCode != 200) return [];

      final html = response.data as String;
      final jsonLdBlocks = _extractJsonLd(html);

      final events = <Event>[];
      for (final block in jsonLdBlocks) {
        final parsed = _parseJsonLdEvent(block, categorie: categorie);
        if (parsed != null) {
          events.add(parsed);
        }
      }

      return events;
    } catch (e) {
      debugPrint('[FestikApiService] Error fetching events: $e');
      return [];
    }
  }

  /// Extrait tous les blocs JSON-LD depuis le HTML.
  List<Map<String, dynamic>> _extractJsonLd(String html) {
    final results = <Map<String, dynamic>>[];
    final regex = RegExp(
      r'<script\s+type="application/ld\+json"\s*>(.*?)</script>',
      dotAll: true,
    );

    for (final match in regex.allMatches(html)) {
      try {
        final raw = match.group(1)?.trim();
        if (raw == null || raw.isEmpty) continue;

        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          if (decoded['@type'] == 'Event') {
            results.add(decoded);
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic> && item['@type'] == 'Event') {
              results.add(item);
            }
          }
        }
      } catch (_) {
        // JSON invalide, on continue
      }
    }

    return results;
  }

  /// Parse un bloc JSON-LD schema.org Event en Event model.
  /// Retourne null si l'evenement n'est pas dans l'agglomeration toulousaine.
  Event? _parseJsonLdEvent(
    Map<String, dynamic> jsonLd, {
    String categorie = 'Festival',
  }) {
    final location = jsonLd['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    final address = location['address'] as Map<String, dynamic>?;
    final city = (address?['addressLocality'] as String?) ?? '';

    // Filtrer par ville
    if (!_isToulouseArea(city)) return null;

    final name = (jsonLd['name'] as String?) ?? '';
    if (name.isEmpty) return null;

    final startDate = (jsonLd['startDate'] as String?) ?? '';
    final endDate = (jsonLd['endDate'] as String?) ?? '';
    final venueName = (location['name'] as String?) ?? '';
    final streetAddress = (address?['streetAddress'] as String?) ?? '';
    final postalCode = (address?['postalCode'] as String?) ?? '';
    final url = (jsonLd['url'] as String?) ?? '';
    final description = (jsonLd['description'] as String?) ?? '';

    // Extraire la date (format ISO 8601 → YYYY-MM-DD)
    final dateDebut = _extractDate(startDate);
    final dateFin = _extractDate(endDate);
    final horaires = _extractTime(startDate);

    final fullAddress = postalCode.isNotEmpty
        ? '$streetAddress, $postalCode $city'
        : '$streetAddress, $city';

    return Event(
      identifiant: 'festik_${name.hashCode}_$dateDebut',
      titre: name,
      descriptifCourt: description.length > 200
          ? '${description.substring(0, 200)}...'
          : description,
      dateDebut: dateDebut,
      dateFin: dateFin,
      horaires: horaires,
      lieuNom: venueName,
      lieuAdresse: fullAddress,
      commune: _normalizeCityName(city),
      categorie: categorie,
      type: categorie,
      manifestationGratuite: 'non',
      reservationUrl: url,
    );
  }

  bool _isToulouseArea(String city) {
    final normalized = city.toLowerCase().trim();
    return _toulouseCities.contains(normalized);
  }

  String _normalizeCityName(String city) {
    final trimmed = city.trim();
    if (trimmed.toLowerCase() == 'toulouse') return 'Toulouse';
    return trimmed;
  }

  /// Extrait YYYY-MM-DD depuis une date ISO 8601.
  String _extractDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    // Format: 2026-03-27T20:30:00+01:00 ou 2026-03-27
    if (isoDate.length >= 10) {
      return isoDate.substring(0, 10);
    }
    return isoDate;
  }

  /// Extrait l'heure HHhMM depuis une date ISO 8601.
  String _extractTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}
