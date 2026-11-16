/// Rutas de la aplicación.
///
/// Usa siempre estas constantes en lugar de escribir strings sueltos.
abstract final class AppRoutes {
  static const String login = '/login';

  static const String home = '/inicio';
  static const String teams = '/equipos';
  static const String tournaments = '/torneos';
  static const String matches = '/partido';
  static const String profile = '/perfil';

  /// Detalle de un equipo dentro de la pestaña Equipos.
  static String teamDetail(String id) => '$teams/$id';

  /// Detalle de un torneo dentro de la pestaña Torneos.
  static String tournamentDetail(String id) => '$tournaments/$id';

  /// Estadísticas personales del usuario.
  static const String myStats = '$profile/estadisticas';

  /// Partido en curso dentro de la pestaña Modo partido.
  static const String liveMatch = '$matches/en-vivo';
}
