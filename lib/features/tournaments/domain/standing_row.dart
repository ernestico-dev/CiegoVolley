import '../../teams/domain/team.dart';

/// Fila de la tabla de posiciones de un torneo.
class StandingRow {
  StandingRow({required this.team});

  final Team team;

  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  int get difference => pointsFor - pointsAgainst;

  /// Puntos de liga: 3 por victoria, 1 por empate.
  int get points => wins * 3 + draws;

  /// Orden: más ganados, menos empates, menos derrotas, mejor diferencia.
  static int compare(StandingRow a, StandingRow b) {
    if (a.wins != b.wins) {
      return b.wins.compareTo(a.wins);
    }
    if (a.draws != b.draws) {
      return a.draws.compareTo(b.draws);
    }
    if (a.losses != b.losses) {
      return a.losses.compareTo(b.losses);
    }
    if (a.difference != b.difference) {
      return b.difference.compareTo(a.difference);
    }
    if (a.pointsFor != b.pointsFor) {
      return b.pointsFor.compareTo(a.pointsFor);
    }
    return a.team.name.toLowerCase().compareTo(b.team.name.toLowerCase());
  }
}
