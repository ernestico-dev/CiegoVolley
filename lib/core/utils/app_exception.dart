/// Error con un mensaje ya listo para enseñar al usuario.
///
/// Se usa cuando la app detecta el problema antes de llamar al backend
/// (por ejemplo, una imagen demasiado grande) y quiere un texto concreto en
/// lugar del mensaje genérico.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
