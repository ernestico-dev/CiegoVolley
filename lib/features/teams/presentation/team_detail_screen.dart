import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/image_picker_helper.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/editable_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../tournaments/domain/team_tournament.dart';
import '../data/team_repository.dart';
import '../domain/team.dart';
import '../domain/team_member.dart';
import 'add_member_sheet.dart';
import 'join_tournament_sheet.dart';
import 'team_form_sheet.dart';

/// Detalle del equipo: datos, integrantes y torneos.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final team = teamAsync.asData?.value;
    final isOwner = team != null && team.ownerId == currentUserId;

    final joinedIds = {
      for (final entry
          in ref.watch(teamTournamentsProvider(teamId)).asData?.value ??
              const <TeamTournament>[])
        entry.tournament.id,
    };

    final memberIds = {
      for (final member
          in ref.watch(teamMembersProvider(teamId)).asData?.value ??
              const <TeamMember>[])
        member.userId,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(team?.name ?? 'Equipo'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Editar equipo',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await TeamFormSheet.showEdit(context, team);
                if (result == TeamFormResult.deleted && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar el equipo',
          message: friendlyErrorMessage(error),
          action: FilledButton(
            onPressed: () => ref.invalidate(teamProvider(teamId)),
            child: const Text('Reintentar'),
          ),
        ),
        data: (team) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teamProvider(teamId));
            ref.invalidate(teamMembersProvider(teamId));
            ref.invalidate(teamTournamentsProvider(teamId));
            await ref.read(teamProvider(teamId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _TeamSummary(team: team, isOwner: isOwner),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Integrantes',
                trailing: isOwner
                    ? TextButton.icon(
                        onPressed: () => AddMemberSheet.show(
                          context,
                          teamId: teamId,
                          excludeUserIds: {...memberIds, team.ownerId},
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Añadir'),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              _MembersSection(
                teamId: teamId,
                isOwner: isOwner,
                ownerId: team.ownerId,
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Torneos',
                trailing: isOwner
                    ? TextButton.icon(
                        onPressed: () => JoinTournamentSheet.show(
                          context,
                          teamId: teamId,
                          joinedIds: joinedIds,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Inscribir'),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              _TournamentsSection(teamId: teamId, isOwner: isOwner),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamSummary extends ConsumerStatefulWidget {
  const _TeamSummary({required this.team, required this.isOwner});

  final Team team;
  final bool isOwner;

  @override
  ConsumerState<_TeamSummary> createState() => _TeamSummaryState();
}

class _TeamSummaryState extends ConsumerState<_TeamSummary> {
  bool _uploading = false;

  Future<void> _pickLogo() async {
    final team = widget.team;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await pickImageFromGallery();
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);

      await ref
          .read(teamRepositoryProvider)
          .updateTeamLogo(
            teamId: team.id,
            bytes: picked.bytes,
            extension: picked.extension,
            previousUrl: team.logoUrl,
          );

      ref.invalidate(teamProvider(team.id));
      ref.invalidate(teamsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Foto del equipo actualizada.')),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Logo de equipo: falló la subida con ${error.runtimeType}: $error',
      );
      debugPrint('$stackTrace');
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final isOwner = widget.isOwner;
    final theme = Theme.of(context);
    final initial = team.name.characters.first.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EditableImage(
                  imageUrl: team.logoUrl,
                  previewTitle: team.name,
                  size: 64,
                  borderRadius: BorderRadius.circular(32),
                  onEdit: isOwner ? _pickLogo : null,
                  uploading: _uploading,
                  fallback: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Categoría ${team.category}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(team.category),
                ),
                if (team.season != null && team.season!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text('Temporada ${team.season}'),
                  ),
                if (isOwner)
                  const Chip(
                    avatar: Icon(Icons.workspace_premium_outlined, size: 18),
                    label: Text('Creador'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MembersSection extends ConsumerWidget {
  const _MembersSection({
    required this.teamId,
    required this.isOwner,
    required this.ownerId,
  });

  final String teamId;
  final bool isOwner;
  final String ownerId;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar integrante?'),
        content: Text(
          '${member.displayName} dejará de formar parte del equipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(teamRepositoryProvider)
          .removeMember(teamId: teamId, userId: member.userId);
      ref.invalidate(teamMembersProvider(teamId));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    return members.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Text(
        friendlyErrorMessage(error),
        style: TextStyle(color: theme.colorScheme.error),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'Todavía no hay integrantes. Añade jugadores por su nombre.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          );
        }

        return Card(
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: UserAvatar(
                    name: list[i].displayName,
                    avatarUrl: list[i].avatarUrl,
                    radius: 20,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  title: Text(
                    list[i].displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(list[i].email),
                  trailing: isOwner && list[i].userId != ownerId
                      ? IconButton(
                          tooltip: 'Quitar del equipo',
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _remove(context, ref, list[i]),
                        )
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TournamentsSection extends ConsumerWidget {
  const _TournamentsSection({required this.teamId, required this.isOwner});

  final String teamId;
  final bool isOwner;

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    TeamTournament entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del torneo?'),
        content: Text(
          'El equipo dejará de estar inscrito en ${entry.tournament.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(teamRepositoryProvider)
          .leaveTournament(teamId: teamId, tournamentId: entry.tournament.id);
      ref.invalidate(teamTournamentsProvider(teamId));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(teamTournamentsProvider(teamId));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM y', 'es');

    return entries.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Text(
        friendlyErrorMessage(error),
        style: TextStyle(color: theme.colorScheme.error),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'El equipo no está inscrito en ningún torneo.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          );
        }

        return Card(
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    foregroundColor: theme.colorScheme.onTertiaryContainer,
                    child: const Icon(Icons.emoji_events_outlined),
                  ),
                  title: Text(
                    list[i].tournament.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      if (list[i].tournament.venue != null)
                        list[i].tournament.venue!,
                      if (list[i].tournament.startsOn != null)
                        dateFormat.format(list[i].tournament.startsOn!),
                    ].join(' · '),
                  ),
                  trailing: isOwner
                      ? IconButton(
                          tooltip: 'Salir del torneo',
                          icon: const Icon(Icons.logout),
                          onPressed: () => _leave(context, ref, list[i]),
                        )
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
