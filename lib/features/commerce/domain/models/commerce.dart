import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/core/utils/emoji_mapper.dart';

part 'commerce.freezed.dart';
part 'commerce.g.dart';

@freezed
class CommerceModel with _$CommerceModel {
  const CommerceModel._();

  const factory CommerceModel({
    @Default('') String nom,
    @Default('') String adresse,
    @Default('') String ville,
    @Default('') String distance,
    @Default(0) int distanceMetres,
    @Default(0.0) double latitude,
    @Default(0.0) double longitude,
    @Default('') String horaires,
    @Default(true) bool ouvert,
    @Default('') String categorie,
    @Default('') String lienMaps,
    @Default('') String telephone,
    @Default('') String avis,
    @Default('') String photo,
    @Default('') String siteWeb,
    @Default(false) bool independant,
  }) = _CommerceModel;

  factory CommerceModel.fromJson(Map<String, dynamic> json) =>
      _$CommerceModelFromJson(json);

  int calculateDistanceFrom(double lat, double lon) {
    return Haversine.distanceInMeters(latitude, longitude, lat, lon).round();
  }

  String get categoryEmoji => EmojiMapper.getCommerceEmoji(categorie);
}
