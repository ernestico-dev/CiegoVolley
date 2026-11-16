/// Estadísticas acumuladas de un jugador en toda la plataforma.
class PlayerStats {
  const PlayerStats({
    required this.userId,
    required this.name,
    required this.successes,
    required this.failures,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.tournaments,
  });

  final String userId;
  final String name;
  final int successes;
  final int failures;
  final int matchesPlayed;
  final int matchesWon;
  final int tournaments;

  int get attempts => successes + failures;

  /// Porcentaje de aciertos (0–100). Sin intentos vale 0.
  int get successPercent {
    if (attempts == 0) return 0;
    return (successes * 100 / attempts).round();
  }

  double get successRate => attempts == 0 ? 0 : successes / attempts;

  /// Intentos mínimos para entrar en el ranking por porcentaje.
  static const minAttempts = 3;

  bool get isRanked => attempts >= minAttempts;

  /// Orden del ranking global: mejor porcentaje, más partidos ganados,
  /// más acciones registradas y, al final, nombre.
  ///
  /// Quien todavía no llega a [minAttempts] aparece después, para que un
  /// único acierto no adelante a quien lleva una temporada entera.
  static int compare(PlayerStats a, PlayerStats b) {
    if (a.isRanked != b.isRanked) return a.isRanked ? -1 : 1;
    if (a.successPercent != b.successPercent) {
      return b.successPercent.compareTo(a.successPercent);
    }
    if (a.matchesWon != b.matchesWon) {
      return b.matchesWon.compareTo(a.matchesWon);
    }
    if (a.attempts != b.attempts) {
      return b.attempts.compareTo(a.attempts);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
