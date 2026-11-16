import '../../teams/domain/team.dart';
import '../../teams/domain/team_member.dart';
import '../../tournaments/domain/tournament.dart';
import 'match_action.dart';

/// Clave de una estadística: jugador + acción.
typedef TallyKey = ({String userId, MatchAction action});

/// Aciertos y fallos de una acción concreta.
class MatchTally {
  const MatchTally({this.successes = 0, this.failures = 0});

  final int successes;
  final int failures;

  int get total => successes + failures;

  MatchTally copyWith({int? successes, int? failures}) {
    return MatchTally(
      successes: successes ?? this.successes,
      failures: failures ?? this.failures,
    );
  }
}

/// Partido en curso. Vive en memoria hasta que se guarda al finalizar.
class MatchDraft {
  const MatchDraft({
    required this.tournament,
    required this.homeTeam,
    required this.awayTeam,
    required this.homePlayers,
    required this.awayPlayers,
    this.homeScore = 0,
    this.awayScore = 0,
    this.tallies = const {},
  });

  final Tournament tournament;
  final Team homeTeam;
  final Team awayTeam;
  final List<TeamMember> homePlayers;
  final List<TeamMember> awayPlayers;
  final int homeScore;
  final int awayScore;
  final Map<TallyKey, MatchTally> tallies;

  MatchTally tallyFor(String userId, MatchAction action) {
    return tallies[(userId: userId, action: action)] ?? const MatchTally();
  }

  /// Equipo al que pertenece un jugador del partido.
  String teamIdOf(String userId) {
    final isHome = homePlayers.any((player) => player.userId == userId);
    return isHome ? homeTeam.id : awayTeam.id;
  }

  MatchDraft copyWith({
    int? homeScore,
    int? awayScore,
    Map<TallyKey, MatchTally>? tallies,
  }) {
    return MatchDraft(
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homePlayers: homePlayers,
      awayPlayers: awayPlayers,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      tallies: tallies ?? this.tallies,
    );
  }
}
