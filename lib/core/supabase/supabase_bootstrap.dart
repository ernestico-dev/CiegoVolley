import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

/// Arranque del cliente de Supabase.
///
/// Si faltan las variables de entorno la app sigue funcionando y muestra una
/// pantalla de configuración en lugar del login.
abstract final class SupabaseBootstrap {
  static Future<bool> initialize() async {
    if (!AppEnv.hasSupabase) {
      debugPrint(
        'Supabase no configurado. Ejecuta la app con '
        '--dart-define-from-file=dart_defines/dev.json',
      );
      return false;
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseKey,
    );
    return true;
  }
}
