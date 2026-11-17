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

  /// Efectividad: (aciertos − fallos) sobre el total de intentos.
  double get efficiency =>
      total == 0 ? 0 : (successes - failures) * 100 / total;

  double efficiencyFor(MatchAction action) => efficiency;

  int efficiencyPercentFor(MatchAction action) => efficiency.round();
}

/// Puntos de un set ya terminado.
class MatchSet {
  const MatchSet({required this.home, required this.away});

  final int home;
  final int away;

  bool get isHomeWin => home > away;

  Map<String, dynamic> toJson() => {'home': home, 'away': away};
}

/// Partido en curso. Vive en memoria hasta que se guarda al finalizar.
class MatchDraft {
  const MatchDraft({
    required this.tournament,
    required this.homeTeam,
    required this.awayTeam,
    required this.homePlayers,
    required this.awayPlayers,
    this.setsCount = 1,
    this.completedSets = const [],
    this.homeScore = 0,
    this.awayScore = 0,
    this.tallies = const {},
  });

  final Tournament tournament;
  final Team homeTeam;
  final Team awayTeam;
  final List<TeamMember> homePlayers;
  final List<TeamMember> awayPlayers;

  /// Cuántos sets tiene el partido (entre 1 y 5).
  final int setsCount;

  /// Sets ya cerrados, en orden.
  final List<MatchSet> completedSets;

  /// Puntos del set que se está jugando.
  final int homeScore;
  final int awayScore;
  final Map<TallyKey, MatchTally> tallies;

  /// Sets ganados por cada equipo (es el resultado final del partido).
  int get homeSetsWon => completedSets.where((set) => set.isHomeWin).length;

  int get awaySetsWon => completedSets.where((set) => !set.isHomeWin).length;

  /// Sets que hay que ganar para llevarse el partido.
  ///
  /// Solo se juega a 1, 3 o 5 sets: en 3 gana el primero que llega a 2 y en 5
  /// el que llega a 3. Nunca hay empate.
  int get setsToWin => (setsCount + 1) ~/ 2;

  /// El partido ya tiene ganador.
  bool get hasWinner => homeSetsWon >= setsToWin || awaySetsWon >= setsToWin;

  /// Número del set en juego (1..setsCount).
  int get currentSet => allSetsPlayed
      ? completedSets.length.clamp(1, setsCount)
      : completedSets.length + 1;

  /// El partido terminó: alguien llegó a [setsToWin].
  bool get allSetsPlayed => hasWinner;

  /// Resultado final por sets, p. ej. `2-1`.
  String get setsScore => '$homeSetsWon-$awaySetsWon';

  /// Un set solo se puede cerrar si no está empatado y hay algún punto.
  bool get canCloseSet {
    if (allSetsPlayed) return false;
    if (homeScore == awayScore) return false;
    return homeScore > 0 || awayScore > 0;
  }

  MatchTally tallyFor(String userId, MatchAction action) {
    return tallies[(userId: userId, action: action)] ?? const MatchTally();
  }

  /// Equipo al que pertenece un jugador del partido.
  String teamIdOf(String userId) {
    final isHome = homePlayers.any((player) => player.userId == userId);
    return isHome ? homeTeam.id : awayTeam.id;
  }

  MatchDraft copyWith({
    int? setsCount,
    List<MatchSet>? completedSets,
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
      setsCount: setsCount ?? this.setsCount,
      completedSets: completedSets ?? this.completedSets,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      tallies: tallies ?? this.tallies,
    );
  }
}
