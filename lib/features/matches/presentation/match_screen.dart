import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../teams/domain/team_member.dart';
import '../../tournaments/data/tournament_repository.dart';
import '../data/match_repository.dart';
import '../domain/match_draft.dart';
import 'match_draft_controller.dart';
import 'widgets/player_stats_panel.dart';
import 'widgets/score_board.dart';
import 'widgets/volleyball_court.dart';

/// Partido en curso: cancha, marcador, estadísticas y cierre.
class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _selectedUserId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(matchDraftProvider);

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modo partido')),
        body: EmptyState(
          icon: Icons.sports_volleyball_outlined,
          title: 'No hay ningún partido en curso',
          message: 'Elige un torneo y dos equipos para empezar.',
          action: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Volver'),
          ),
        ),
      );
    }

    final selected = _findPlayer(draft, _selectedUserId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.tournament.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '${draft.homeTeam.name} vs ${draft.awayTeam.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: VolleyballCourt(
                draft: draft,
                selectedUserId: _selectedUserId,
                onSelect: (player) =>
                    setState(() => _selectedUserId = player.userId),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ScoreBoard(
                draft: draft,
                onHomeAdd: () =>
                    ref.read(matchDraftProvider.notifier).addPoint(home: true),
                onHomeRemove: () => ref
                    .read(matchDraftProvider.notifier)
                    .removePoint(home: true),
                onAwayAdd: () =>
                    ref.read(matchDraftProvider.notifier).addPoint(home: false),
                onAwayRemove: () => ref
                    .read(matchDraftProvider.notifier)
                    .removePoint(home: false),
                onUndoSet: draft.completedSets.isEmpty
                    ? null
                    : () => ref.read(matchDraftProvider.notifier).undoLastSet(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: selected == null
                    ? const _SelectHint()
                    : PlayerStatsPanel(
                        player: selected.player,
                        teamName: selected.teamName,
                        draft: draft,
                        onRegister: (action, {required success}) => ref
                            .read(matchDraftProvider.notifier)
                            .register(
                              selected.player.userId,
                              action,
                              success: success,
                            ),
                        onUndo: (action, {required success}) => ref
                            .read(matchDraftProvider.notifier)
                            .undo(
                              selected.player.userId,
                              action,
                              success: success,
                            ),
                        onClose: () => setState(() => _selectedUserId = null),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (draft.allSetsPlayed)
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _finish(draft),
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.flag_outlined),
                      label: const Text('Finalizar partido'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : () => _closeSet(draft),
                            icon: const Icon(Icons.done_all),
                            label: Text('Cerrar set ${draft.currentSet}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => _finish(draft),
                            child: const Text('Finalizar'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _saving ? null : _reset,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reiniciar partido'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({TeamMember player, String teamName})? _findPlayer(
    MatchDraft draft,
    String? userId,
  ) {
    if (userId == null) return null;

    for (final player in draft.homePlayers) {
      if (player.userId == userId) {
        return (player: player, teamName: draft.homeTeam.name);
      }
    }
    for (final player in draft.awayPlayers) {
      if (player.userId == userId) {
        return (player: player, teamName: draft.awayTeam.name);
      }
    }
    return null;
  }

  /// Cierra el set en juego y avisa cuando ya no quedan más.
  void _closeSet(MatchDraft draft) {
    final messenger = ScaffoldMessenger.of(context);
    final closed = ref.read(matchDraftProvider.notifier).closeSet();

    if (!closed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Para cerrar el set el marcador no puede estar empatado ni a cero.',
          ),
        ),
      );
      return;
    }

    final next = ref.read(matchDraftProvider);
    if (next == null) return;

    if (next.allSetsPlayed) {
      final winner = next.isDraw
          ? 'Empate ${next.setsScore}'
          : 'Gana ${next.homeSetsWon > next.awaySetsWon ? next.homeTeam.name : next.awayTeam.name} '
                '${next.setsScore}';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Partido completo. $winner. Pulsa Finalizar para guardarlo.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Set cerrado (${next.setsScore}). Empieza el set '
            '${next.currentSet} de ${next.setsCount}.',
          ),
        ),
      );
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Reiniciar partido?'),
        content: const Text(
          'El marcador volverá a cero, se borrarán los sets jugados y las '
          'estadísticas registradas hasta ahora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    ref.read(matchDraftProvider.notifier).reset();
    if (mounted) setState(() => _selectedUserId = null);
  }

  Future<void> _finish(MatchDraft draft) async {
    final choice = await showDialog<_FinishChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar partido'),
        content: const Text(
          '¿Quieres guardar los datos del partido o salir sin guardarlos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_FinishChoice.discard),
            child: const Text('Salir sin guardar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_FinishChoice.save),
            child: const Text('Guardar datos'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          choice == _FinishChoice.save
              ? '¿Guardar el partido?'
              : '¿Salir sin guardar?',
        ),
        content: Text(
          choice == _FinishChoice.save
              ? 'Se guardará el resultado por sets y las estadísticas de los '
                    'jugadores.'
              : 'Se perderán el resultado y las estadísticas de este partido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              choice == _FinishChoice.save ? 'Sí, guardar' : 'Sí, salir',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (choice == _FinishChoice.discard) {
      ref.read(matchDraftProvider.notifier).clear();
      if (mounted) context.pop();
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(matchRepositoryProvider).saveMatch(draft);
      ref.read(matchDraftProvider.notifier).clear();

      final tournamentId = draft.tournament.id;
      ref.invalidate(tournamentMatchesProvider(tournamentId));
      ref.invalidate(standingsProvider(tournamentId));
      ref.invalidate(bracketProvider(tournamentId));
      ref.invalidate(tournamentProvider(tournamentId));
      ref.invalidate(tournamentsProvider);

      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Partido guardado.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }
}

enum _FinishChoice { save, discard }

class _SelectHint extends StatelessWidget {
  const _SelectHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca un jugador de la cancha para registrar sus acciones.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
