import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Traduce los errores más comunes del backend a mensajes para el usuario.
String friendlyErrorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is AuthException) return _translate(error.message);
  if (error is PostgrestException) return _postgrest(error);
  if (error is StorageException) return _storage(error);
  if (error is PlatformException) return _platform(error);
  if (error is AuthRetryableFetchException) return _noConnection;

  // En depuración mostramos el detalle: sin él es imposible saber qué falla.
  if (kDebugMode) return 'Algo salió mal: $error';
  return 'Algo salió mal. Inténtalo de nuevo.';
}

const String _noConnection =
    'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';

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

/// Mensaje legible para un fallo de Storage (avatares, archivos).
String _storage(StorageException error) {
  final message = error.message.toLowerCase();
  final status = error.statusCode;

  if (message.contains('bucket not found')) {
    return 'El espacio de avatares no existe en Supabase. '
        'Ejecuta la migración 20261116000005_avatars_notifications.sql.';
  }
  if (message.contains('row-level security') ||
      message.contains('unauthorized') ||
      status == '401' ||
      status == '403') {
    return 'Tu sesión no permite subir la imagen. '
        'Vuelve a entrar y prueba otra vez.';
  }
  if (message.contains('too large') ||
      message.contains('payload') ||
      message.contains('maximum allowed size') ||
      status == '413') {
    return 'La imagen es demasiado grande. Usa una de menos de 5 MB.';
  }
  if (message.contains('mime') || message.contains('content-type')) {
    return 'Ese formato de imagen no está permitido. '
        'Usa JPG, PNG o WebP.';
  }
  if (message.contains('duplicate') || message.contains('already exists')) {
    return 'Ya existe una imagen con ese nombre. Inténtalo de nuevo.';
  }

  final detail = error.message.trim();
  final suffix = detail.isEmpty ? '' : ': $detail';
  return status == null
      ? 'No se pudo subir la imagen$suffix'
      : 'No se pudo subir la imagen (error $status)$suffix';
}

String _platform(PlatformException error) {
  return switch (error.code) {
    'already_active' =>
      'El selector de fotos ya está abierto. Ciérralo e inténtalo de nuevo.',
    'photo_access_denied' || 'camera_access_denied' =>
      'La app no tiene permiso para acceder a tus fotos. '
          'Actívalo en los ajustes del teléfono.',
    'invalid_image' => 'No pudimos leer esa imagen. Prueba con otra.',
    _ => 'No se pudo abrir el selector de fotos. Inténtalo de nuevo.',
  };
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
