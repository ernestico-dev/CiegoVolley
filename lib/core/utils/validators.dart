/// Validadores reutilizables para formularios.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo';
    if (!_email.hasMatch(text)) return 'El correo no es válido';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe una contraseña';
    if (text.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? requiredText(String? value, {String field = 'Este campo'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field es obligatorio';
    return null;
  }
}
