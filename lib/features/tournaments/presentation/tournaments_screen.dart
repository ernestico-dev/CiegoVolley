import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/editable_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../profile/data/profile_repository.dart';
import '../data/tournament_repository.dart';
import '../domain/tournament.dart';
import 'tournament_form_sheet.dart';

/// Torneos de la plataforma.
///
/// Todo el mundo puede verlos; solo el administrador del club puede crear,
/// editar y eliminar (el RLS de `tournaments` lo impone en el servidor).
class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentsProvider);
    final isAdmin = ref.watch(isAdminProvider);

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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => TournamentFormSheet.showCreate(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo torneo'),
            )
          : null,
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
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Todavía no hay torneos',
                message: isAdmin
                    ? 'Crea el primer torneo con el botón de abajo.'
                    : 'El administrador del club todavía no ha creado ninguno.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tournament = list[index];
                return _TournamentCard(
                  tournament: tournament,
                  onTap: () =>
                      context.push(AppRoutes.tournamentDetail(tournament.id)),
                  onEdit: isAdmin
                      ? () => TournamentFormSheet.showEdit(context, tournament)
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onTap,
    this.onEdit,
  });

  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditableImage(
                imageUrl: tournament.imageUrl,
                previewTitle: tournament.name,
                size: 52,
                borderRadius: BorderRadius.circular(12),
                backgroundColor: theme.colorScheme.tertiaryContainer,
                fallback: Icon(
                  Icons.emoji_events_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
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
              if (onEdit != null)
                IconButton(
                  tooltip: 'Editar torneo',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
            ],
          ),
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
