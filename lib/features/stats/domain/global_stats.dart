import '../../matches/domain/match_action.dart';
import 'action_leader.dart';
import 'player_stats.dart';
import 'team_stats.dart';

/// Resumen estadístico de toda la plataforma.
class GlobalStats {
  const GlobalStats({
    required this.players,
    required this.teams,
    required this.leaders,
    required this.actionTotals,
    required this.totalSuccesses,
    required this.totalFailures,
    required this.matchCount,
    required this.tournamentCount,
  });

  /// Ranking de jugadores (ya ordenado).
  final List<PlayerStats> players;

  /// Equipos con partidos jugados (ya ordenados).
  final List<TeamStats> teams;

  /// Mejor jugador por acción, si hay datos suficientes.
  final Map<MatchAction, ActionLeader> leaders;

  /// Acciones registradas por tipo.
  final Map<MatchAction, int> actionTotals;

  final int totalSuccesses;
  final int totalFailures;
  final int matchCount;
  final int tournamentCount;

  int get totalActions => totalSuccesses + totalFailures;

  bool get isEmpty => totalActions == 0 && matchCount == 0;

  TeamStats? get bestTeam => teams.isEmpty ? null : teams.first;

  ActionLeader? leaderFor(MatchAction action) => leaders[action];

  /// Porcentaje global de aciertos (0–100).
  int get successPercent {
    if (totalActions == 0) return 0;
    return (totalSuccesses * 100 / totalActions).round();
  }

  static const empty = GlobalStats(
    players: [],
    teams: [],
    leaders: {},
    actionTotals: {},
    totalSuccesses: 0,
    totalFailures: 0,
    matchCount: 0,
    tournamentCount: 0,
  );
}
