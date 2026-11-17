import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../profile/data/profile_repository.dart';
import '../../teams/data/team_repository.dart';
import '../../tournaments/data/tournament_repository.dart';
import '../../tournaments/domain/tournament.dart';
import '../domain/match_draft.dart';
import 'match_draft_controller.dart';

/// Punto de entrada del modo partido: se elige el torneo y los dos equipos.
class MatchModeScreen extends ConsumerStatefulWidget {
  const MatchModeScreen({super.key});

  @override
  ConsumerState<MatchModeScreen> createState() => _MatchModeScreenState();
}

class _MatchModeScreenState extends ConsumerState<MatchModeScreen> {
  String? _tournamentId;
  String? _homeTeamId;
  String? _awayTeamId;
  int _setsCount = 3;
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modo partido')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Solo el administrador',
          message:
              'El modo partido está reservado al administrador del club. '
              'Si necesitas dirigir un partido, pídeselo a Ernesto Carbonell.',
        ),
      );
    }

    final tournaments = ref.watch(tournamentsProvider);
    final draft = ref.watch(matchDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo partido'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () {
              ref.invalidate(tournamentsProvider);
              final id = _tournamentId;
              if (id != null) ref.invalidate(tournamentTeamsProvider(id));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: tournaments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar los torneos',
          message: friendlyErrorMessage(error),
          action: FilledButton(
            onPressed: () => ref.invalidate(tournamentsProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (draft != null) ...[
              _LiveMatchCard(draft: draft),
              const SizedBox(height: 16),
            ],
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Todavía no hay torneos',
                message:
                    'El administrador del club debe crear un torneo y los '
                    'equipos inscribirse para poder jugar.',
              )
            else
              _SetupCard(
                tournaments: list,
                tournamentId: _tournamentId,
                homeTeamId: _homeTeamId,
                awayTeamId: _awayTeamId,
                setsCount: _setsCount,
                starting: _starting,
                onSetsChanged: (value) => setState(() => _setsCount = value),
                onTournamentChanged: (id) => setState(() {
                  _tournamentId = id;
                  _homeTeamId = null;
                  _awayTeamId = null;
                }),
                onHomeChanged: (id) => setState(() => _homeTeamId = id),
                onAwayChanged: (id) => setState(() => _awayTeamId = id),
                onStart: () => _start(list),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(List<Tournament> tournaments) async {
    final tournamentId = _tournamentId;
    final homeId = _homeTeamId;
    final awayId = _awayTeamId;

    if (tournamentId == null || homeId == null || awayId == null) return;
    if (homeId == awayId) return;

    setState(() => _starting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final tournament = tournaments.firstWhere((t) => t.id == tournamentId);
      final teams = await ref.read(
        tournamentTeamsProvider(tournamentId).future,
      );

      final home = teams.firstWhere((team) => team.id == homeId);
      final away = teams.firstWhere((team) => team.id == awayId);

      final homePlayers = await ref.read(teamMembersProvider(home.id).future);
      final awayPlayers = await ref.read(teamMembersProvider(away.id).future);

      if (homePlayers.isEmpty || awayPlayers.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Cada equipo necesita al menos un integrante para jugar.',
            ),
          ),
        );
        if (mounted) setState(() => _starting = false);
        return;
      }

      ref
          .read(matchDraftProvider.notifier)
          .start(
            tournament: tournament,
            homeTeam: home,
            awayTeam: away,
            homePlayers: homePlayers,
            awayPlayers: awayPlayers,
            setsCount: _setsCount,
          );

      if (!mounted) return;
      setState(() => _starting = false);
      context.push(AppRoutes.liveMatch);
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }
}

class _LiveMatchCard extends ConsumerWidget {
  const _LiveMatchCard({required this.draft});

  final MatchDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_volleyball,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partido en curso',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  '${draft.homeSetsWon} - ${draft.awaySetsWon}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${draft.homeTeam.name} vs ${draft.awayTeam.name} · '
              '${draft.allSetsPlayed ? 'partido terminado' : 'set ${draft.currentSet} de ${draft.setsCount}'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.liveMatch),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continuar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Descartar partido',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('¿Descartar partido?'),
                        content: const Text(
                          'Se perderán el marcador y las estadísticas '
                          'registradas hasta ahora.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('No'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Sí, descartar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      ref.read(matchDraftProvider.notifier).clear();
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends ConsumerWidget {
  const _SetupCard({
    required this.tournaments,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.setsCount,
    required this.starting,
    required this.onSetsChanged,
    required this.onTournamentChanged,
    required this.onHomeChanged,
    required this.onAwayChanged,
    required this.onStart,
  });

  final List<Tournament> tournaments;
  final String? tournamentId;
  final String? homeTeamId;
  final String? awayTeamId;
  final int setsCount;
  final bool starting;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<String?> onTournamentChanged;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<String?> onAwayChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = tournamentId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo partido',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _Dropdown<String>(
              label: 'Torneo',
              icon: Icons.emoji_events_outlined,
              value: selected,
              items: [
                for (final tournament in tournaments)
                  DropdownMenuItem(
                    value: tournament.id,
                    child: Text(tournament.name),
                  ),
              ],
              onChanged: onTournamentChanged,
            ),
            const SizedBox(height: 16),
            _SetsSelector(value: setsCount, onChanged: onSetsChanged),
            if (selected == null) ...[
              const SizedBox(height: 12),
              Text(
                'Elige el torneo para cargar sus equipos inscritos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              _TeamsPicker(
                tournamentId: selected,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                onHomeChanged: onHomeChanged,
                onAwayChanged: onAwayChanged,
                onStart: onStart,
                starting: starting,
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamsPicker extends ConsumerWidget {
  const _TeamsPicker({
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.onHomeChanged,
    required this.onAwayChanged,
    required this.onStart,
    required this.starting,
  });

  final String tournamentId;
  final String? homeTeamId;
  final String? awayTeamId;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<String?> onAwayChanged;
  final VoidCallback onStart;
  final bool starting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teams = ref.watch(tournamentTeamsProvider(tournamentId));

    return teams.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          friendlyErrorMessage(error),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
      data: (list) {
        if (list.length < 2) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Este torneo necesita al menos dos equipos inscritos. '
              'Inscríbelos desde la pantalla de cada equipo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _Dropdown<String>(
              label: 'Equipo local',
              icon: Icons.home_outlined,
              value: homeTeamId,
              items: [
                for (final team in list)
                  if (team.id != awayTeamId)
                    DropdownMenuItem(value: team.id, child: Text(team.name)),
              ],
              onChanged: onHomeChanged,
            ),
            const SizedBox(height: 12),
            _Dropdown<String>(
              label: 'Equipo visitante',
              icon: Icons.flight_takeoff,
              value: awayTeamId,
              items: [
                for (final team in list)
                  if (team.id != homeTeamId)
                    DropdownMenuItem(value: team.id, child: Text(team.name)),
              ],
              onChanged: onAwayChanged,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: starting || homeTeamId == null || awayTeamId == null
                  ? null
                  : onStart,
              icon: starting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Comenzar partido'),
            ),
          ],
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          isDense: true,
          value: value,
          hint: const Text('Selecciona…'),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Selector de cuántos sets tiene el partido (1 a 5).
class _SetsSelector extends StatelessWidget {
  const _SetsSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sets del partido',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value == 1 ? '1 set' : '$value sets',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final sets in const [1, 3, 5])
              ChoiceChip(
                label: Text('$sets'),
                selected: value == sets,
                onSelected: (_) => onChanged(sets),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Al mejor de $value sets: gana el primero que consiga '
          '${(value + 1) ~/ 2} set${(value + 1) ~/ 2 == 1 ? '' : 's'}. '
          'Nunca hay empate.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
