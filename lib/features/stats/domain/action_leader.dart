import '../../matches/domain/match_action.dart';

/// Mejor jugador de una acción concreta (saque, ataque, defensa o bloqueo).
class ActionLeader {
  const ActionLeader({
    required this.action,
    required this.userId,
    required this.name,
    required this.successes,
    required this.failures,
  });

  final MatchAction action;
  final String userId;
  final String name;
  final int successes;
  final int failures;

  int get attempts => successes + failures;

  int get efficiencyPercent {
    if (attempts == 0) return 0;
    return ((successes - failures) * 100 / attempts).round();
  }

  int get successPercent => efficiencyPercent;

  /// Orden dentro de una acción: mejor porcentaje y más aciertos.
  static int compare(ActionLeader a, ActionLeader b) {
    if (a.efficiencyPercent != b.efficiencyPercent) {
      return b.efficiencyPercent.compareTo(a.efficiencyPercent);
    }
    if (a.successes != b.successes) {
      return b.successes.compareTo(a.successes);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
