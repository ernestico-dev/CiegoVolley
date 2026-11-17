import '../../matches/domain/match_action.dart';

/// Aciertos y fallos de una acción concreta.
class ActionTally {
  const ActionTally({
    this.successes = 0,
    this.failures = 0,
    this.neutrals = 0,
    this.blocked = 0,
  });

  final int successes;
  final int failures;
  final int neutrals;
  final int blocked;

  int get total => successes + failures + neutrals + blocked;

  int get successPercent {
    if (total == 0) return 0;
    return (successes * 100 / total).round();
  }

  double efficiencyFor(MatchAction action) => switch (action) {
    MatchAction.serve => _percent(successes - failures),
    MatchAction.attack => _percent(successes - failures - blocked),
    MatchAction.defense => _percent(successes - failures),
    MatchAction.block => _percent(successes - failures),
  };

  int efficiencyPercentFor(MatchAction action) => efficiencyFor(action).round();

  double _percent(int numerator) => total == 0 ? 0 : numerator * 100 / total;
}

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
    this.actions = const {},
  });

  final String userId;
  final String name;
  final int successes;
  final int failures;
  final int matchesPlayed;
  final int matchesWon;
  final int tournaments;

  /// Aciertos y fallos por fundamento.
  final Map<MatchAction, ActionTally> actions;

  int get attempts => successes + failures;

  /// Porcentaje de aciertos (0–100). Sin intentos vale 0.
  int get successPercent {
    if (attempts == 0) return 0;
    return (successes * 100 / attempts).round();
  }

  double get successRate => attempts == 0 ? 0 : successes / attempts;

  ActionTally tallyFor(MatchAction action) {
    return actions[action] ?? const ActionTally();
  }

  /// Fundamento con mejor porcentaje (con al menos un intento).
  MatchAction? get bestAction {
    MatchAction? best;
    for (final action in MatchAction.values) {
      final tally = tallyFor(action);
      if (tally.total == 0) continue;
      if (best == null) {
        best = action;
        continue;
      }
      final current = tallyFor(best);
      final efficiency = tally.efficiencyPercentFor(action);
      final currentEfficiency = current.efficiencyPercentFor(best);
      if (efficiency > currentEfficiency ||
          (efficiency == currentEfficiency &&
              tally.successes > current.successes)) {
        best = action;
      }
    }
    return best;
  }

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
