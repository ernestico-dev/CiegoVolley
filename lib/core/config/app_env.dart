/// Configuración de la aplicación leída en tiempo de compilación.
///
/// Los valores se inyectan con `--dart-define` o, más cómodo, con
/// `--dart-define-from-file=dart_defines/dev.json`.
///
/// Nunca subas tus claves a git: `dart_defines/*.json` está ignorado.
abstract final class AppEnv {
  static const String appName = 'CiegoVolley';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Puede ser la *anon key* clásica o la nueva *publishable key*.
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
