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

    final subscription = auth.onAuthStateChange.listen((state) {
      this.state = state.session;
    });
    ref.onDispose(subscription.cancel);

    return auth.currentSession;
  }
}

/// Usuario autenticado (o `null`).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});
