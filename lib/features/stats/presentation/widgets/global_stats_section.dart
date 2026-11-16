import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../matches/domain/match_action.dart';
import '../../data/stats_repository.dart';
import '../../domain/action_leader.dart';
import '../../domain/global_stats.dart';
import '../../domain/player_stats.dart';
import 'action_colors.dart';
import 'player_stats_carousel.dart';

/// Estadísticas globales del club: donas, rankings y mejores por acción.
class GlobalStatsSection extends ConsumerWidget {
  const GlobalStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(globalStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Estadísticas globales',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar estadísticas',
              onPressed: () => ref.invalidate(globalStatsProvider),
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        stats.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                friendlyErrorMessage(error),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
          data: (data) {
            if (data.isEmpty) {
              return const _NoStats();
            }
            return _StatsBody(stats: data);
          },
        ),
      ],
    );
  }
}

class _NoStats extends StatelessWidget {
  const _NoStats();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.query_stats_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay estadísticas',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando el administrador dirija un partido en Modo partido y '
              'guarde los datos, aquí aparecerán los rankings y las gráficas.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final GlobalStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerStatsCarousel(players: stats.players),
        const SizedBox(height: 16),
        _Leaderboard(players: stats.players),
        const SizedBox(height: 16),
        _ActionLeaders(leaders: stats.leaders),
        const SizedBox(height: 16),
        _BestTeamCard(stats: stats),
      ],
    );
  }
}

/// Carrusel con las estadísticas de cada jugador registrado.
class _Leaderboard extends ConsumerWidget {
  const _Leaderboard({required this.players});

  final List<PlayerStats> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myId = ref.watch(currentUserProvider)?.id;
    final top = players.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Mejores jugadores',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '% de aciertos, partidos ganados y torneos jugados.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  'Aún no hay acciones registradas por jugador.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              _LeaderboardTable(players: top, myId: myId),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({required this.players, this.myId});

  final List<PlayerStats> players;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final cellStyle = theme.textTheme.bodySmall;

    Widget cell(String text, TextStyle? style, {bool center = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: style,
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(24),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(44),
        3: FixedColumnWidth(34),
        4: FixedColumnWidth(34),
      },
      children: [
        TableRow(
          children: [
            cell('#', headerStyle, center: true),
            cell('Jugador', headerStyle),
            cell('%', headerStyle, center: true),
            cell('G', headerStyle, center: true),
            cell('T', headerStyle, center: true),
          ],
        ),
        for (var i = 0; i < players.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: players[i].userId == myId
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : i.isEven
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    )
                  : null,
            ),
            children: [
              cell('${i + 1}', cellStyle, center: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  players[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              cell(
                '${players[i].successPercent}%',
                cellStyle?.copyWith(fontWeight: FontWeight.w700),
                center: true,
              ),
              cell('${players[i].matchesWon}', cellStyle, center: true),
              cell('${players[i].tournaments}', cellStyle, center: true),
            ],
          ),
      ],
    );
  }
}

class _ActionLeaders extends StatelessWidget {
  const _ActionLeaders({required this.leaders});

  final Map<MatchAction, ActionLeader> leaders;

  static const _icons = {
    MatchAction.serve: Icons.sports_volleyball_rounded,
    MatchAction.attack: Icons.flash_on_rounded,
    MatchAction.defense: Icons.shield_outlined,
    MatchAction.block: Icons.front_hand_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Los mejores por fundamento',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final action in MatchAction.values)
              _LeaderCard(
                action: action,
                leader: leaders[action],
                icon: _icons[action] ?? Icons.star_outline,
              ),
          ],
        ),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.action,
    required this.leader,
    required this.icon,
  });

  final MatchAction action;
  final ActionLeader? leader;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = actionColor(theme.colorScheme, action);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              leader?.name ?? 'Sin datos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              leader == null
                  ? 'Aún no hay intentos suficientes'
                  : '${leader!.successPercent}% · ${leader!.successes} '
                        'de ${leader!.attempts}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestTeamCard extends StatelessWidget {
  const _BestTeamCard({required this.stats});

  final GlobalStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = stats.bestTeam;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              foregroundColor: theme.colorScheme.onTertiaryContainer,
              child: const Icon(Icons.workspace_premium_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mejor equipo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    best?.team.name ?? 'Sin partidos jugados',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (best != null)
                    Text(
                      '${best.wins} ganados de ${best.played} '
                      '(${best.winPercent}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (best != null)
              Text(
                '${best.winPercent}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
