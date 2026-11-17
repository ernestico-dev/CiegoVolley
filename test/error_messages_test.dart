import 'package:ciego_volley/core/utils/app_exception.dart';
import 'package:ciego_volley/core/utils/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('los errores propios muestran su mensaje tal cual', () {
    expect(
      friendlyErrorMessage(const AppException('La imagen pesa demasiado.')),
      'La imagen pesa demasiado.',
    );
  });

  test('un bucket inexistente explica que falta la migración', () {
    final error = StorageException(
      'Bucket not found',
      statusCode: '400',
      error: 'NoSuchBucket',
    );

    final message = friendlyErrorMessage(error);
    expect(message, contains('avatares'));
    expect(message, contains('20261116000005'));
  });

  test('un fallo de políticas pide volver a entrar', () {
    final error = StorageException(
      'new row violates row-level security policy',
      statusCode: '400',
    );

    expect(friendlyErrorMessage(error), contains('Vuelve a entrar'));
  });

  test('una imagen demasiado grande lo dice con claridad', () {
    final error = StorageException(
      'The object exceeded the maximum allowed size',
      statusCode: '413',
    );

    expect(friendlyErrorMessage(error), contains('5 MB'));
  });

  test('los fallos desconocidos no filtran detalles en release', () {
    expect(
      friendlyErrorMessage(StateError('algo raro')),
      contains('Algo salió mal'),
    );
  });

  test('traduce las credenciales incorrectas', () {
    final error = AuthException('Invalid login credentials');

    expect(friendlyErrorMessage(error), 'Correo o contraseña incorrectos.');
  });
}
