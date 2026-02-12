import 'package:freezed_annotation/freezed_annotation.dart';

part 'football_match.freezed.dart';
part 'football_match.g.dart';

@freezed
class FootballMatch with _$FootballMatch {
  const factory FootballMatch({
    @Default(0) int id,
    required FootballTeam homeTeam,
    required FootballTeam awayTeam,
    required FootballCompetition competition,
    @Default('') String utcDate,
    @Default('') String status,
    FootballScore? score,
  }) = _FootballMatch;

  factory FootballMatch.fromJson(Map<String, dynamic> json) =>
      _$FootballMatchFromJson(json);
}

@freezed
class FootballTeam with _$FootballTeam {
  const factory FootballTeam({
    @Default(0) int id,
    @Default('') String name,
    @Default('') String shortName,
    @Default('') String crest,
  }) = _FootballTeam;

  factory FootballTeam.fromJson(Map<String, dynamic> json) =>
      _$FootballTeamFromJson(json);
}

@freezed
class FootballCompetition with _$FootballCompetition {
  const factory FootballCompetition({
    @Default(0) int id,
    @Default('') String name,
    @Default('') String emblem,
  }) = _FootballCompetition;

  factory FootballCompetition.fromJson(Map<String, dynamic> json) =>
      _$FootballCompetitionFromJson(json);
}

@freezed
class FootballScore with _$FootballScore {
  const factory FootballScore({
    @Default('') String winner,
    FootballScoreDetail? fullTime,
    FootballScoreDetail? halfTime,
  }) = _FootballScore;

  factory FootballScore.fromJson(Map<String, dynamic> json) =>
      _$FootballScoreFromJson(json);
}

@freezed
class FootballScoreDetail with _$FootballScoreDetail {
  const factory FootballScoreDetail({
    int? home,
    int? away,
  }) = _FootballScoreDetail;

  factory FootballScoreDetail.fromJson(Map<String, dynamic> json) =>
      _$FootballScoreDetailFromJson(json);
}
