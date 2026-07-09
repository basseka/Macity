import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_agenda_event.freezed.dart';
part 'open_agenda_event.g.dart';

@freezed
class OpenAgendaEvent with _$OpenAgendaEvent {
  const OpenAgendaEvent._();

  const factory OpenAgendaEvent({
    @Default('') String uid,
    @Default('') String title,
    @Default('') String description,
    @Default('') String longDescription,
    @Default('') String dateRange,
    @Default('') String firstDate,
    @Default('') String lastDate,
    @Default('') String locationName,
    @Default('') String locationAddress,
    @Default('') String locationCity,
    @Default('') String locationPostalcode,
    @Default(0.0) double locationLatitude,
    @Default(0.0) double locationLongitude,
    @Default('') String keywords,
    @Default('') String image,
    @Default('') String link,
    @Default('') String pricing,
    @Default(false) bool isFree,
  }) = _OpenAgendaEvent;

  factory OpenAgendaEvent.fromJson(Map<String, dynamic> json) =>
      _$OpenAgendaEventFromJson(json);

  // Extrait lat/lon d'un champ geo hétérogène : map {'lat','lon'} ou liste
  // GeoJSON [lon, lat].
  static double _coord(dynamic raw, String which) {
    if (raw is Map) {
      final v = raw[which] ?? raw[which == 'lat' ? 'latitude' : 'longitude'];
      return (v as num?)?.toDouble() ?? 0.0;
    }
    if (raw is List && raw.length >= 2) {
      // GeoJSON = [lon, lat]
      final v = which == 'lat' ? raw[1] : raw[0];
      return (v as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  factory OpenAgendaEvent.fromApiRecord(Map<String, dynamic> record) {
    final fields = record['fields'] ?? record;
    return OpenAgendaEvent(
      uid: fields['uid']?.toString() ?? '',
      title: fields['title_fr'] ?? fields['title'] ?? '',
      description: fields['description_fr'] ?? fields['description'] ?? '',
      longDescription:
          fields['longdescription_fr'] ?? fields['longdescription'] ?? '',
      dateRange: fields['daterange_fr'] ?? '',
      firstDate: fields['firstdate_begin'] ?? '',
      lastDate: fields['lastdate_end'] ?? '',
      locationName: fields['location_name'] ?? '',
      locationAddress: fields['location_address'] ?? '',
      locationCity: fields['location_city'] ?? '',
      locationPostalcode: fields['location_postalcode'] ?? '',
      // location_coordinates : v2.1 renvoie {'lon':.., 'lat':..} (map) ;
      // certains exports renvoient [lon, lat] (liste GeoJSON). On gère les deux.
      locationLatitude: _coord(fields['location_coordinates'], 'lat'),
      locationLongitude: _coord(fields['location_coordinates'], 'lon'),
      keywords: fields['keywords_fr'] ?? '',
      image: fields['image'] ?? '',
      link: fields['canonicalurl'] ?? '',
      pricing: fields['pricing_info'] ?? '',
      isFree: fields['pricing_type'] == 'free',
    );
  }
}
