import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/team_repository.dart';
import '../domain/team.dart';
import 'team_form_sheet.dart';

/// Lista de equipos del club.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => ref.invalidate(teamsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TeamFormSheet.showCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo equipo'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teamsProvider.future),
        child: teams.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos cargar los equipos',
            message: friendlyErrorMessage(error),
            action: FilledButton(
              onPressed: () => ref.invalidate(teamsProvider),
              child: const Text('Reintentar'),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.groups_outlined,
                title: 'Todavía no hay equipos',
                message:
                    'Crea el primer equipo con el botón de abajo. '
                    'Después podrás añadir integrantes e inscribirlo en torneos.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _TeamCard(team: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = team.name.characters.first.toUpperCase();

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            _capitalize(team.category),
            if (team.season != null && team.season!.isNotEmpty)
              'Temporada ${team.season}',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.teamDetail(team.id)),
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
