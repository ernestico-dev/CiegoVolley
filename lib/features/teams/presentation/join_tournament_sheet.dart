import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tournaments/data/tournament_repository.dart';
import '../../tournaments/domain/tournament.dart';
import '../data/team_repository.dart';

/// Lista los torneos disponibles e inscribe al equipo en el elegido.
class JoinTournamentSheet extends ConsumerStatefulWidget {
  const JoinTournamentSheet({
    super.key,
    required this.teamId,
    required this.joinedIds,
  });

  final String teamId;
  final Set<String> joinedIds;

  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    required Set<String> joinedIds,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          JoinTournamentSheet(teamId: teamId, joinedIds: joinedIds),
    );
  }

  @override
  ConsumerState<JoinTournamentSheet> createState() =>
      _JoinTournamentSheetState();
}

class _JoinTournamentSheetState extends ConsumerState<JoinTournamentSheet> {
  String? _joiningId;
  String? _error;

  Future<void> _join(Tournament tournament) async {
    setState(() {
      _joiningId = tournament.id;
      _error = null;
    });

    try {
      await ref
          .read(teamRepositoryProvider)
          .joinTournament(teamId: widget.teamId, tournamentId: tournament.id);
      ref.invalidate(teamTournamentsProvider(widget.teamId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _joiningId = null;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tournaments = ref.watch(tournamentsProvider);
    final dateFormat = DateFormat('d MMM y', 'es');

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inscribir en un torneo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: tournaments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  friendlyErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (list) {
                final available = list
                    .where((t) => !widget.joinedIds.contains(t.id))
                    .toList();

                if (available.isEmpty) {
                  return const EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No hay torneos disponibles',
                    message:
                        'Ya estás inscrito en todos, o todavía no se ha creado '
                        'ninguno.',
                  );
                }

                return ListView.separated(
                  itemCount: available.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tournament = available[index];
                    final joining = _joiningId == tournament.id;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          foregroundColor:
                              theme.colorScheme.onTertiaryContainer,
                          child: const Icon(Icons.emoji_events_outlined),
                        ),
                        title: Text(
                          tournament.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (tournament.venue != null) tournament.venue!,
                            if (tournament.startsOn != null)
                              dateFormat.format(tournament.startsOn!),
                          ].join(' · '),
                        ),
                        trailing: joining
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton(
                                onPressed: _joiningId == null
                                    ? () => _join(tournament)
                                    : null,
                                child: const Text('Inscribir'),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
