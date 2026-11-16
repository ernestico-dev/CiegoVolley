import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce los errores más comunes del backend a mensajes para el usuario.
String friendlyErrorMessage(Object error) {
  if (error is AuthException) return _translate(error.message);
  if (error is PostgrestException) return _postgrest(error);
  return 'Algo salió mal. Inténtalo de nuevo.';
}

/// Mensaje legible para un fallo de PostgREST, con el código entre corchetes
/// para poder diagnosticar sin abrir la consola.
String _postgrest(PostgrestException error) {
  final base = switch (error.code) {
    '23503' =>
      'Falta el perfil del usuario en la base de datos. '
          'Ejecuta el backfill de perfiles en Supabase.',
    '23514' => 'Algún dato no cumple las reglas de la tabla.',
    '23505' => 'Ese registro ya existe.',
    '42501' => 'Las políticas RLS no permiten esta operación.',
    'PGRST205' => 'La tabla no existe. ¿Ejecutaste la migración?',
    'PGRST301' => 'La sesión ha caducado. Vuelve a entrar.',
    _ => 'No se pudo completar la operación en la base de datos.',
  };

  final code = error.code;
  return code == null ? base : '$base [$code]';
}

const Map<String, String> _translations = {
  'invalid login credentials': 'Correo o contraseña incorrectos.',
  'email not confirmed': 'Debes confirmar tu correo antes de entrar.',
  'user already registered': 'Ya existe una cuenta con ese correo.',
  'password should be at least 6 characters':
      'La contraseña debe tener al menos 6 caracteres.',
  'unable to validate email address: invalid format':
      'El correo no tiene un formato válido.',
};

String _translate(String message) {
  final lower = message.toLowerCase();
  for (final entry in _translations.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return message;
}
