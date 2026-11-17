import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../matches/domain/match_action.dart';
import '../../profile/data/profile_repository.dart';
import '../data/stats_repository.dart';
import '../domain/global_stats.dart';
import '../domain/player_stats.dart';
import 'widgets/action_colors.dart';
import 'widgets/donut_chart.dart';
import 'widgets/player_stats_carousel.dart';

/// Estadísticas personales del usuario con sesión iniciada.
class MyStatsScreen extends ConsumerWidget {
  const MyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(globalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estadísticas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(globalStatsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar tus estadísticas',
          message: friendlyErrorMessage(error),
          action: FilledButton(
            onPressed: () => ref.invalidate(globalStatsProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (data) {
          final player = _findPlayer(data, ref.watch(currentUserProvider)?.id);
          if (player == null) {
            return EmptyState(
              icon: Icons.query_stats_rounded,
              title: 'Todavía no tienes estadísticas',
              message:
                  'Cuando el administrador guarde un partido en el que hayas '
                  'participado, aquí verás tus aciertos, fallos y torneos.',
              action: FilledButton(
                onPressed: () => ref.invalidate(globalStatsProvider),
                child: const Text('Actualizar'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _PlayerHeader(player: player, stats: data),
              const SizedBox(height: 16),
              _Charts(player: player),
              const SizedBox(height: 16),
              _ActionsTable(player: player),
              const SizedBox(height: 16),
              Text(
                'Los porcentajes se calculan con todas las acciones que el '
                'administrador registró en tus partidos.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static PlayerStats? _findPlayer(GlobalStats stats, String? userId) {
    if (userId == null) return null;
    for (final player in stats.players) {
      if (player.userId == userId) return player;
    }
    return null;
  }
}

class _PlayerHeader extends ConsumerWidget {
  const _PlayerHeader({required this.player, required this.stats});

  final PlayerStats player;
  final GlobalStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider).asData?.value;
    final position = stats.players.indexWhere((p) => p.userId == player.userId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            UserAvatar(
              name: player.name,
              avatarUrl: profile?.avatarUrl,
              radius: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.matchesPlayed} partidos · '
                    '${player.matchesWon} ganados · '
                    '${player.tournaments} torneos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (position >= 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Puesto ${position + 1} de ${stats.players.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.player});

  final PlayerStats player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Efectividad',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DonutChart(
                    slices: [
                      DonutSlice(
                        label: 'Aciertos',
                        value: player.successes,
                        color: scheme.primary,
                      ),
                      DonutSlice(
                        label: 'Fallos',
                        value: player.failures,
                        color: scheme.error,
                      ),
                    ],
                    centerValue: '${player.successPercent}%',
                  ),
                  const SizedBox(height: 8),
                  LegendItem(
                    color: scheme.primary,
                    label: 'Aciertos',
                    value: '${player.successes}',
                  ),
                  LegendItem(
                    color: scheme.error,
                    label: 'Fallos',
                    value: '${player.failures}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Acciones',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DonutChart(
                    slices: [
                      for (final action in MatchAction.values)
                        DonutSlice(
                          label: action.label,
                          value: player.tallyFor(action).total,
                          color: actionColor(scheme, action),
                        ),
                    ],
                    centerValue: '${player.attempts}',
                  ),
                  const SizedBox(height: 8),
                  for (final action in MatchAction.values)
                    LegendItem(
                      color: actionColor(scheme, action),
                      label: action.label,
                      value: '${player.tallyFor(action).total}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsTable extends StatelessWidget {
  const _ActionsTable({required this.player});

  final PlayerStats player;

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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: style,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Por fundamento',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FixedColumnWidth(38),
                2: FixedColumnWidth(38),
                3: FixedColumnWidth(48),
              },
              children: [
                TableRow(
                  children: [
                    cell('Acción', headerStyle),
                    cell('Aciertos', headerStyle, center: true),
                    cell('Fallos', headerStyle, center: true),
                    cell('Efic.', headerStyle, center: true),
                  ],
                ),
                for (final action in MatchAction.values)
                  TableRow(
                    decoration: BoxDecoration(
                      color: action.index.isEven
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35)
                          : null,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 9,
                              width: 9,
                              decoration: BoxDecoration(
                                color: actionColor(theme.colorScheme, action),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(action.label, style: cellStyle),
                          ],
                        ),
                      ),
                      cell(
                        '${player.tallyFor(action).successes}',
                        cellStyle,
                        center: true,
                      ),
                      cell(
                        '${player.tallyFor(action).failures}',
                        cellStyle,
                        center: true,
                      ),
                      cell(
                        player.tallyFor(action).total == 0
                            ? '—'
                            : '${player.tallyFor(action).efficiencyPercentFor(action)}%',
                        cellStyle?.copyWith(fontWeight: FontWeight.w700),
                        center: true,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
