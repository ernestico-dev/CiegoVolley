/// Acciones que se registran por jugador durante un partido.
enum MatchAction {
  serve('serve', 'Saque'),
  attack('attack', 'Ataque'),
  defense('defense', 'Defensa'),
  block('block', 'Bloqueo');

  const MatchAction(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static MatchAction? fromDb(String value) {
    for (final action in MatchAction.values) {
      if (action.dbValue == value) return action;
    }
    return null;
  }
}
