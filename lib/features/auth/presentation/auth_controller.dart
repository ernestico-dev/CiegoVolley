import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Resultado de un registro.
enum SignUpResult {
  /// La sesión ya está activa (confirmación de correo desactivada).
  signedIn,

  /// Hay que confirmar el correo antes de poder entrar.
  confirmationRequired,
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Estado de las operaciones de autenticación.
///
/// `isLoading` sirve para deshabilitar formularios y `hasError` para mostrar
/// el último fallo. Los métodos relanzan la excepción para que la pantalla
/// pueda mostrar un mensaje contextual.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) {
    return _run(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, fullName: fullName);
      state = const AsyncData(null);
      return response.session == null
          ? SignUpResult.confirmationRequired
          : SignUpResult.signedIn;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<void> sendPasswordReset(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).sendPasswordReset(email),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    if (result.hasError) {
      Error.throwWithStackTrace(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
    }
  }
}
