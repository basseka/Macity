import 'package:freezed_annotation/freezed_annotation.dart';

part 'ville.freezed.dart';
part 'ville.g.dart';

@freezed
class VilleModel with _$VilleModel {
  const VilleModel._();

  const factory VilleModel({
    required String nom,
    @Default('') String codePostal,
    @Default('') String departement,
    @Default(0) int population,
  }) = _VilleModel;

  factory VilleModel.fromJson(Map<String, dynamic> json) =>
      _$VilleModelFromJson(json);

  String get displayName => '$nom ($codePostal)';

  String get populationFormatted {
    if (population == 0) return '';
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M hab.';
    }
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}K hab.';
    }
    return '$population hab.';
  }
}
