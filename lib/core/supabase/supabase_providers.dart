import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente global de Supabase.
///
/// Solo debe leerse cuando [SupabaseBootstrap.initialize] terminó con éxito.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Sesión actual, disponible de forma síncrona desde el primer frame.
///
/// Escucha `onAuthStateChange` para mantenerse al día con login, logout y
/// refresco de tokens.
final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    final auth = ref.watch(supabaseClientProvider).auth;

    final subscription = auth.onAuthStateChange.listen(
      (state) {
        debugPrint(
          '[auth] ${state.event.name} · sesión=${state.session != null} · '
          'motivo=${state.signOutReason?.name} · '
          'otraPestaña=${state.fromBroadcast}',
        );

        if (state.event == AuthChangeEvent.signedIn) {
          ref.read(sessionEndedProvider.notifier).clear();
        }

        final next = state.session;
        if (next != null) {
          this.state = next;
          return;
        }

        // Un `null` que no sea un cierre de sesión explícito no debe sacar
        // al usuario de la app: a veces el SDK avisa sin sesión (por ejemplo
        // al refrescar el token) y antes eso devolvía al login.
        final current = auth.currentSession;
        if (current != null) {
          this.state = current;
          return;
        }

        if (state.event == AuthChangeEvent.signedOut) {
          final reason = state.signOutReason;
          debugPrint(
            '[auth] sesión cerrada: ${reason?.name ?? 'sin motivo indicado'}',
          );

          if (reason != SignOutReason.userInitiated) {
            ref.read(sessionEndedProvider.notifier).mark();
          }

          this.state = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[auth] error en el estado de sesión: $error');
      },
    );
    ref.onDispose(subscription.cancel);

    return auth.currentSession;
  }
}

/// `true` cuando la sesión se cerró sin que el usuario lo pidiera.
///
/// El login lo usa para explicar por qué ha vuelto a la pantalla de entrada.
final sessionEndedProvider = NotifierProvider<SessionEndedNotifier, bool>(
  SessionEndedNotifier.new,
);

class SessionEndedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;

  void clear() {
    if (state) state = false;
  }
}

/// Usuario autenticado (o `null`).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Política de reintentos desactivada.
///
/// Riverpod 3 reintenta por defecto con backoff exponencial. Eso hace que un
/// fallo permanente (tabla inexistente, RLS, migración sin ejecutar) se repita
/// muchas veces, llene la consola de 404 y deje la pantalla cargando. Aquí el
/// usuario refresca a mano cuando quiera.
Duration? noRetry(int retryCount, Object error) => null;
