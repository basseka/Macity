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

  factory OpenAgendaEvent.fromApiRecord(Map<String, dynamic> record) {
    final fields = record['fields'] ?? record;
    return OpenAgendaEvent(
      uid: fields['uid']?.toString() ?? '',
      title: fields['title_fr'] ?? fields['title'] ?? '',
      description: fields['description_fr'] ?? fields['description'] ?? '',
      longDescription: fields['longdescription_fr'] ?? fields['longdescription'] ?? '',
      dateRange: fields['daterange_fr'] ?? '',
      firstDate: fields['firstdate_begin'] ?? '',
      lastDate: fields['lastdate_end'] ?? '',
      locationName: fields['location_name'] ?? '',
      locationAddress: fields['location_address'] ?? '',
      locationCity: fields['location_city'] ?? '',
      locationPostalcode: fields['location_postalcode'] ?? '',
      locationLatitude: (fields['location_coordinates']?[0] as num?)?.toDouble() ?? 0.0,
      locationLongitude: (fields['location_coordinates']?[1] as num?)?.toDouble() ?? 0.0,
      keywords: fields['keywords_fr'] ?? '',
      image: fields['image'] ?? '',
      link: fields['canonicalurl'] ?? '',
      pricing: fields['pricing_info'] ?? '',
      isFree: fields['pricing_type'] == 'free',
    );
  }
}
