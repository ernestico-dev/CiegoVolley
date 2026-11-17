import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../teams/domain/team.dart';
import '../../teams/domain/team_member.dart';
import '../../tournaments/domain/tournament.dart';
import '../domain/match_action.dart';
import '../domain/match_draft.dart';

/// Partido en curso. `null` cuando no hay ninguno abierto.
///
/// Se mantiene en memoria: los datos solo viajan a Supabase al finalizar.
final matchDraftProvider = NotifierProvider<MatchDraftController, MatchDraft?>(
  MatchDraftController.new,
);

class MatchDraftController extends Notifier<MatchDraft?> {
  @override
  MatchDraft? build() => null;

  void start({
    required Tournament tournament,
    required Team homeTeam,
    required Team awayTeam,
    required List<TeamMember> homePlayers,
    required List<TeamMember> awayPlayers,
    int setsCount = 3,
  }) {
    state = MatchDraft(
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homePlayers: homePlayers,
      awayPlayers: awayPlayers,
      // Solo se juega a 1, 3 o 5 sets.
      setsCount: switch (setsCount) {
        1 => 1,
        5 => 5,
        _ => 3,
      },
    );
  }

  void addPoint({required bool home}) {
    final draft = state;
    if (draft == null) return;

    state = home
        ? draft.copyWith(homeScore: draft.homeScore + 1)
        : draft.copyWith(awayScore: draft.awayScore + 1);
  }

  void removePoint({required bool home}) {
    final draft = state;
    if (draft == null) return;

    if (home) {
      state = draft.copyWith(
        homeScore: draft.homeScore > 0 ? draft.homeScore - 1 : 0,
      );
    } else {
      state = draft.copyWith(
        awayScore: draft.awayScore > 0 ? draft.awayScore - 1 : 0,
      );
    }
  }

  void register(String userId, MatchAction action, {required bool success}) {
    final draft = state;
    if (draft == null) return;

    final key = (userId: userId, action: action);
    final current = draft.tallies[key] ?? const MatchTally();

    state = draft.copyWith(
      tallies: {
        ...draft.tallies,
        key: success
            ? current.copyWith(successes: current.successes + 1)
            : current.copyWith(failures: current.failures + 1),
      },
    );
  }

  /// Resta un acierto o un fallo (para corregir un toque de más).
  void undo(String userId, MatchAction action, {required bool success}) {
    final draft = state;
    if (draft == null) return;

    final key = (userId: userId, action: action);
    final current = draft.tallies[key];
    if (current == null) return;

    final next = success
        ? current.copyWith(
            successes: current.successes > 0 ? current.successes - 1 : 0,
          )
        : current.copyWith(
            failures: current.failures > 0 ? current.failures - 1 : 0,
          );

    final tallies = {...draft.tallies};
    if (next.total == 0) {
      tallies.remove(key);
    } else {
      tallies[key] = next;
    }

    state = draft.copyWith(tallies: tallies);
  }

  /// Cierra el set en juego y empieza el siguiente.
  ///
  /// Devuelve `false` si no se puede cerrar (empate, sin puntos o ya no
  /// quedan sets).
  bool closeSet() {
    final draft = state;
    if (draft == null || !draft.canCloseSet) return false;

    state = draft.copyWith(
      completedSets: [
        ...draft.completedSets,
        MatchSet(home: draft.homeScore, away: draft.awayScore),
      ],
      homeScore: 0,
      awayScore: 0,
    );
    return true;
  }

  /// Pone a cero los puntos del set en juego sin tocar los sets ya cerrados.
  ///
  /// Sirve para corregir un set que se estaba apuntando mal.
  void resetCurrentSet() {
    final draft = state;
    if (draft == null || draft.allSetsPlayed) return;

    state = draft.copyWith(homeScore: 0, awayScore: 0);
  }

  /// Deshace el último set cerrado y devuelve sus puntos al marcador.
  void undoLastSet() {
    final draft = state;
    if (draft == null || draft.completedSets.isEmpty) return;

    final last = draft.completedSets.last;
    state = draft.copyWith(
      completedSets: draft.completedSets.sublist(
        0,
        draft.completedSets.length - 1,
      ),
      homeScore: last.home,
      awayScore: last.away,
    );
  }

  /// Marcador a cero y estadísticas limpias, sin salir del partido.
  void reset() {
    final draft = state;
    if (draft == null) return;

    state = draft.copyWith(
      completedSets: const [],
      homeScore: 0,
      awayScore: 0,
      tallies: const {},
    );
  }

  void clear() => state = null;
}
