/// Partido guardado de un torneo (solo lo necesario para la tabla).
class MatchResult {
  const MatchResult({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.stage,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final String stage;

  bool get isDraw => homeScore == awayScore;

  String? get winnerTeamId {
    if (isDraw) return null;
    return homeScore > awayScore ? homeTeamId : awayTeamId;
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      id: map['id'] as String,
      homeTeamId: map['home_team_id'] as String? ?? '',
      awayTeamId: map['away_team_id'] as String? ?? '',
      homeScore: (map['home_score'] as num?)?.toInt() ?? 0,
      awayScore: (map['away_score'] as num?)?.toInt() ?? 0,
      stage: map['stage'] as String? ?? 'league',
    );
  }
}
