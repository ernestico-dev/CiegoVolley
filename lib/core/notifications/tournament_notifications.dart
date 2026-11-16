import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/profile_repository.dart';
import '../../features/tournaments/data/tournament_repository.dart';
import '../../features/tournaments/domain/tournament.dart';
import 'notification_bridge.dart';

/// Vigila si aparecen torneos nuevos mientras la app está abierta.
///
/// Solo se activa si el usuario encendió las notificaciones en su perfil.
final tournamentNotificationWatcherProvider = Provider<void>((ref) {
  final profile = ref.watch(myProfileProvider).asData?.value;
  final enabled = profile?.notificationsEnabled ?? false;

  if (!enabled || !notificationsAvailable) return;

  final watcher = _TournamentWatcher(ref);
  watcher.start();
  ref.onDispose(watcher.stop);
});

class _TournamentWatcher {
  _TournamentWatcher(this._ref);

  final Ref _ref;
  Timer? _timer;
  Set<String>? _known;
  bool _busy = false;

  static const _interval = Duration(seconds: 45);

  void start() {
    _poll(initial: true);
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll({bool initial = false}) async {
    if (_busy) return;
    _busy = true;

    try {
      final tournaments = await _ref
          .read(tournamentRepositoryProvider)
          .fetchTournaments();
      final ids = tournaments.map((tournament) => tournament.id).toSet();

      // La primera pasada solo memoriza lo que ya existe.
      if (_known == null || initial) {
        _known = ids;
        return;
      }

      final fresh = tournaments
          .where((tournament) => !_known!.contains(tournament.id))
          .toList();
      _known = ids;

      if (fresh.isEmpty) return;

      _ref.invalidate(tournamentsProvider);

      if (notificationPermission != 'granted') return;
      for (final tournament in fresh) {
        _notify(tournament);
      }
    } catch (_) {
      // Sin conexión o sin sesión: se reintenta en la siguiente pasada.
    } finally {
      _busy = false;
    }
  }

  void _notify(Tournament tournament) {
    showLocalNotification(
      'Nuevo torneo: ${tournament.name}',
      [
        if (tournament.venue != null) tournament.venue!,
        'Ya puedes verlo y apuntar a tu equipo.',
      ].join(' · '),
    );
  }
}
