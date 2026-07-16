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
    // Quartier (ex: Capitole, Saint-Cyprien). Rempli par reverse geocoding
    // cote base ; vide = non renseigne (la fiche sort alors des filtres par
    // quartier).
    @Default('') String quartier,
    @Default('') String lienMaps,
    @Default('') String telephone,
    @Default('') String avis,
    @Default('') String photo,
    @Default('') String siteWeb,
    @Default(false) bool independant,
    @Default(0) int displayCount,
    @Default('') String videoUrl,
    @Default(false) bool isVerified,
    // Restaurant partenaire (mis en avant : badge doré carte + fiche).
    @Default(false) bool isPartner,
    // ID + table source pour relier des avis (commerce_reviews.target_*).
    // Nullables : les commerces fabriques sans backing DB (OSM enrichi, fallbacks)
    // n'ont pas d'identifiant stable et ne supportent pas les avis.
    int? sourceId,
    String? sourceTable,
    // Description multi-paragraphes (chain-level ou specifique salle).
    // Affichee dans la fiche detail, sous le header.
    @Default('') String description,
    // Gallery photos officielles (array d'URLs). Affichee en haut de la
    // fiche detail. Tombe sur [photo] (single) si vide.
    @Default(<String>[]) List<String> photos,
  }) = _CommerceModel;

  factory CommerceModel.fromJson(Map<String, dynamic> json) =>
      _$CommerceModelFromJson(json);

  int calculateDistanceFrom(double lat, double lon) {
    return Haversine.distanceInMeters(latitude, longitude, lat, lon).round();
  }

  String get categoryEmoji => EmojiMapper.getCommerceEmoji(categorie);
}
