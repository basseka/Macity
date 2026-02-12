import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_commune.freezed.dart';
part 'geo_commune.g.dart';

@freezed
class GeoCommune with _$GeoCommune {
  const factory GeoCommune({
    required String nom,
    required String code,
    @Default('') String codeDepartement,
    @Default('') String codeRegion,
    @Default([]) List<String> codesPostaux,
    @Default(0) int population,
  }) = _GeoCommune;

  factory GeoCommune.fromJson(Map<String, dynamic> json) =>
      _$GeoCommuneFromJson(json);
}
