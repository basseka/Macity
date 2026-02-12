// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'supabase_match.freezed.dart';
part 'supabase_match.g.dart';

@freezed
class SupabaseMatch with _$SupabaseMatch {
  const factory SupabaseMatch({
    @Default(0) int id,
    @Default('') String sport,
    @Default('') String competition,
    @JsonKey(name: 'equipe_dom') @Default('') String equipe1,
    @JsonKey(name: 'equipe_ext') @Default('') String equipe2,
    @Default('') String date,
    @Default('') String heure,
    @Default('') String lieu,
    @Default('') String ville,
    @Default('') String description,
    @Default('') String score,
    @Default('') String gratuit,
    @JsonKey(name: 'url') @Default('') String billetterie,
    @Default('') String source,
  }) = _SupabaseMatch;

  factory SupabaseMatch.fromJson(Map<String, dynamic> json) =>
      _$SupabaseMatchFromJson(json);
}
