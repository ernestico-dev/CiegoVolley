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
  }) {
    state = MatchDraft(
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homePlayers: homePlayers,
      awayPlayers: awayPlayers,
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

  /// Marcador a cero y estadísticas limpias, sin salir del partido.
  void reset() {
    final draft = state;
    if (draft == null) return;

    state = draft.copyWith(homeScore: 0, awayScore: 0, tallies: const {});
  }

  void clear() => state = null;
}
