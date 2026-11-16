import '../../teams/domain/team.dart';
import 'tournament.dart';

/// Un cruce del cuadro eliminatorio.
class TournamentSlot {
  const TournamentSlot({
    required this.id,
    required this.stage,
    required this.position,
    this.homeTeam,
    this.awayTeam,
    this.matchId,
    this.homeScore,
    this.awayScore,
  });

  final String id;
  final TournamentStage stage;
  final int position;
  final Team? homeTeam;
  final Team? awayTeam;
  final String? matchId;
  final int? homeScore;
  final int? awayScore;

  bool get hasResult =>
      matchId != null && homeScore != null && awayScore != null;

  String? get winnerTeamId {
    if (!hasResult) return null;
    final home = homeTeam?.id;
    final away = awayTeam?.id;
    if (home == null || away == null) return null;
    if (homeScore == awayScore) return null;
    return (homeScore! > awayScore!) ? home : away;
  }

  factory TournamentSlot.fromMap(Map<String, dynamic> map) {
    final home = map['home'] as Map<String, dynamic>?;
    final away = map['away'] as Map<String, dynamic>?;
    final match = map['match'] as Map<String, dynamic>?;

    return TournamentSlot(
      id: map['id'] as String,
      stage: TournamentStage.fromDb(map['stage'] as String?),
      position: (map['position'] as num?)?.toInt() ?? 0,
      homeTeam: home == null ? null : Team.fromMap(home),
      awayTeam: away == null ? null : Team.fromMap(away),
      matchId: map['match_id'] as String?,
      homeScore: (match?['home_score'] as num?)?.toInt(),
      awayScore: (match?['away_score'] as num?)?.toInt(),
    );
  }
}
