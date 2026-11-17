import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/editable_image.dart';
import '../../stats/data/stats_repository.dart';
import '../../stats/presentation/widgets/global_stats_section.dart';
import '../../teams/data/team_repository.dart';
import '../../tournaments/data/tournament_repository.dart';
import '../../tournaments/domain/tournament.dart';

/// Pantalla principal con resumen, torneos en curso y estadísticas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final teams = ref.watch(teamsProvider);
    final tournaments = ref.watch(tournamentsProvider);
    final stats = ref.watch(globalStatsProvider);

    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] as String?)?.trim();
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').first
        : user?.email?.split('@').first ?? 'deportista';

    final today = DateFormat.yMMMMEEEEd('es').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Hola, $name',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _capitalize(today),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.groups_rounded,
                  label: 'Equipos',
                  value: teams.when(
                    data: (list) => '${list.length}',
                    loading: () => '—',
                    error: (error, stackTrace) => '—',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Torneos',
                  value: tournaments.when(
                    data: (list) => '${list.length}',
                    loading: () => '—',
                    error: (error, stackTrace) => '—',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.sports_volleyball_rounded,
                  label: 'Partidos',
                  value: stats.when(
                    data: (data) => '${data.matchCount}',
                    loading: () => '—',
                    error: (error, stackTrace) => '—',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _CurrentTournaments(tournaments: tournaments),
          const SizedBox(height: 24),
          const GlobalStatsSection(),
        ],
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

/// Acceso rápido a los torneos que todavía no han finalizado.
class _CurrentTournaments extends StatelessWidget {
  const _CurrentTournaments({required this.tournaments});

  final AsyncValue<List<Tournament>> tournaments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = tournaments.asData?.value
        .where((tournament) => !tournament.isFinished)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Torneos en curso',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        //  const SizedBox(height: 2),
        //  Text(
        //    'Solo los torneos que todavía no han finalizado.',
        //    style: theme.textTheme.labelSmall?.copyWith(
        //      color: theme.colorScheme.onSurfaceVariant,
        //    ),
        //  ),
        const SizedBox(height: 10),
        if (tournaments.hasError)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      friendlyErrorMessage(tournaments.error!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (active == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (active.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay torneos en curso ahora mismo.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...active.map(
            (tournament) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TournamentTile(tournament: tournament),
            ),
          ),
      ],
    );
  }
}

class _TournamentTile extends StatelessWidget {
  const _TournamentTile({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM', 'es');

    final dates = switch ((tournament.startsOn, tournament.endsOn)) {
      (final start?, final end?) =>
        '${dateFormat.format(start)} – ${dateFormat.format(end)}',
      (final start?, null) => dateFormat.format(start),
      _ => 'Fechas por confirmar',
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.tournamentDetail(tournament.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              EditableImage(
                imageUrl: tournament.imageUrl,
                previewTitle: tournament.name,
                size: 40,
                borderRadius: BorderRadius.circular(10),
                fallback: Icon(
                  Icons.emoji_events_outlined,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (tournament.venue != null) tournament.venue!,
                        dates,
                        tournament.stage.label,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
