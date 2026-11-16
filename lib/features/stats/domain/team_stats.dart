import '../../teams/domain/team.dart';

/// Rendimiento de un equipo a partir de los partidos guardados.
class TeamStats {
  const TeamStats({
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  final Team team;
  final int played;
  final int wins;
  final int draws;
  final int losses;

  int get winPercent {
    if (played == 0) return 0;
    return (wins * 100 / played).round();
  }

  /// Orden: más ganados, mejor porcentaje y menos partidos jugados.
  static int compare(TeamStats a, TeamStats b) {
    if (a.wins != b.wins) return b.wins.compareTo(a.wins);
    if (a.winPercent != b.winPercent) {
      return b.winPercent.compareTo(a.winPercent);
    }
    if (a.played != b.played) return a.played.compareTo(b.played);
    return a.team.name.toLowerCase().compareTo(b.team.name.toLowerCase());
  }
}
