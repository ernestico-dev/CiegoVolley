import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/tournament_repository.dart';
import '../domain/tournament.dart';

/// Torneos de la plataforma.
///
/// De momento es una vista de solo lectura: la creación y la gestión de
/// cuadros llegan en la siguiente parte. Los equipos ya pueden inscribirse
/// desde su pantalla de detalle.
class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => ref.invalidate(tournamentsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tournamentsProvider.future),
        child: tournaments.when(
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
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Todavía no hay torneos',
                message:
                    'Ejecuta supabase/seed.sql para crear torneos de ejemplo '
                    'y poder inscribir equipos.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _TournamentCard(tournament: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM y', 'es');

    final dates = switch ((tournament.startsOn, tournament.endsOn)) {
      (final start?, final end?) =>
        '${dateFormat.format(start)} – ${dateFormat.format(end)}',
      (final start?, null) => dateFormat.format(start),
      _ => 'Fechas por confirmar',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              foregroundColor: theme.colorScheme.onTertiaryContainer,
              child: const Icon(Icons.emoji_events_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (tournament.venue != null) tournament.venue!,
                      dates,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(status: tournament.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  static const _labels = {
    'draft': 'Borrador',
    'published': 'Publicado',
    'finished': 'Finalizado',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPublished = status == 'published';
    final isFinished = status == 'finished';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFinished
            ? scheme.surfaceContainerHighest
            : isPublished
            ? scheme.primaryContainer
            : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isFinished
              ? scheme.onSurfaceVariant
              : isPublished
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
