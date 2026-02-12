// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
class Event with _$Event {
  const Event._();

  const factory Event({
    @Default('') String identifiant,
    @JsonKey(name: 'nom_de_la_manifestation') @Default('') String titre,
    @JsonKey(name: 'descriptif_court') @Default('') String descriptifCourt,
    @JsonKey(name: 'descriptif_long') @Default('') String descriptifLong,
    @JsonKey(name: 'date_debut') @Default('') String dateDebut,
    @JsonKey(name: 'date_fin') @Default('') String dateFin,
    @Default('') String horaires,
    @JsonKey(name: 'dates_affichage_horaires') @Default('') String datesAffichageHoraires,
    @JsonKey(name: 'lieu_nom') @Default('') String lieuNom,
    @JsonKey(name: 'lieu_adresse_2') @Default('') String lieuAdresse,
    @JsonKey(name: 'code_postal') @Default(0) int codePostal,
    @Default('') String commune,
    @JsonKey(name: 'type_de_manifestation') @Default('') String type,
    @JsonKey(name: 'categorie_de_la_manifestation') @Default('') String categorie,
    @JsonKey(name: 'theme_de_la_manifestation') @Default('') String theme,
    @JsonKey(name: 'manifestation_gratuite') @Default('') String manifestationGratuite,
    @JsonKey(name: 'tarif_normal') @Default('') String tarifNormal,
    @JsonKey(name: 'reservation_site_internet') @Default('') String reservationUrl,
    @JsonKey(name: 'reservation_telephone') @Default('') String reservationTelephone,
    @JsonKey(name: 'station_metro_tram_a_proximite') @Default('') String stationProximite,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(null) String? photoPath,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  bool get isFree =>
      manifestationGratuite.toLowerCase() == 'oui' ||
      manifestationGratuite.toLowerCase() == 'true';

  String get categoryEmoji {
    final cat = categorie.toLowerCase();
    if (cat.contains('musique') || cat.contains('concert')) return '🎵';
    if (cat.contains('festival')) return '🎪';
    if (cat.contains('theatre') || cat.contains('théâtre')) return '🎭';
    if (cat.contains('danse')) return '💃';
    if (cat.contains('exposition') || cat.contains('expo')) return '🎨';
    if (cat.contains('cinema') || cat.contains('cinéma')) return '🎬';
    if (cat.contains('litterature') || cat.contains('littérature')) return '📖';
    if (cat.contains('enfant') || cat.contains('jeune')) return '👶';
    if (cat.contains('nature')) return '🌿';
    if (cat.contains('sport')) return '⚽';
    if (cat.contains('patrimoine')) return '🏛️';
    return '📌';
  }
}
