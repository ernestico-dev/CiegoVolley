import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce los errores más comunes del backend a mensajes para el usuario.
String friendlyErrorMessage(Object error) {
  if (error is AuthException) return _translate(error.message);
  if (error is PostgrestException) {
    return 'No se pudo completar la operación en la base de datos. '
        'Revisa las políticas de acceso (RLS).';
  }
  return 'Algo salió mal. Inténtalo de nuevo.';
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
