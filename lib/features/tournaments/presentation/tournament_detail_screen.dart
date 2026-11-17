import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/image_picker_helper.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/editable_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../profile/data/profile_repository.dart';
import '../../teams/domain/team.dart';
import '../data/tournament_repository.dart';
import '../domain/standing_row.dart';
import '../domain/tournament.dart';
import '../domain/tournament_slot.dart';
import 'tournament_form_sheet.dart';
import 'widgets/tournament_bracket.dart';

/// Detalle de un torneo: posiciones, cuadro eliminatorio y gestión.
class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final isAdmin = ref.watch(isAdminProvider);
    final tournament = tournamentAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament?.name ?? 'Torneo'),
        actions: [
          if (isAdmin && tournament != null)
            IconButton(
              tooltip: 'Editar torneo',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await TournamentFormSheet.showEdit(context, tournament);
                ref.invalidate(tournamentProvider(tournamentId));
              },
            ),
        ],
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar el torneo',
          message: friendlyErrorMessage(error),
          action: FilledButton(
            onPressed: () => ref.invalidate(tournamentProvider(tournamentId)),
            child: const Text('Reintentar'),
          ),
        ),
        data: (tournament) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tournamentProvider(tournamentId));
            ref.invalidate(standingsProvider(tournamentId));
            ref.invalidate(tournamentMatchesProvider(tournamentId));
            ref.invalidate(bracketProvider(tournamentId));
            await ref.read(tournamentProvider(tournamentId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(tournament: tournament, isAdmin: isAdmin),
              const SizedBox(height: 20),
              _StandingsSection(tournamentId: tournamentId),
              const SizedBox(height: 20),
              _BracketSection(tournament: tournament, isAdmin: isAdmin),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.tournament, required this.isAdmin});

  final Tournament tournament;
  final bool isAdmin;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool _uploading = false;

  Future<void> _pickImage() async {
    final tournament = widget.tournament;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await pickImageFromGallery(maxSide: 1600);
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);

      await ref
          .read(tournamentRepositoryProvider)
          .updateTournamentImage(
            tournamentId: tournament.id,
            bytes: picked.bytes,
            extension: picked.extension,
            previousUrl: tournament.imageUrl,
          );

      ref.invalidate(tournamentProvider(tournament.id));
      ref.invalidate(tournamentsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Foto del torneo actualizada.')),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Imagen de torneo: falló la subida con ${error.runtimeType}: $error',
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
    final tournament = widget.tournament;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM y', 'es');

    final dates = switch ((tournament.startsOn, tournament.endsOn)) {
      (final start?, final end?) =>
        '${dateFormat.format(start)} – ${dateFormat.format(end)}',
      (final start?, null) => dateFormat.format(start),
      _ => 'Fechas por confirmar',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditableImage(
          imageUrl: tournament.imageUrl,
          previewTitle: tournament.name,
          aspectRatio: 16 / 9,
          onEdit: widget.isAdmin ? _pickImage : null,
          uploading: _uploading,
          fallback: Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (tournament.venue != null) tournament.venue!,
                    dates,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: _statusLabel(tournament.status)),
                    _Chip(label: tournament.stage.label, highlighted: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'draft' => 'Borrador',
      'published' => 'Publicado',
      'finished' => 'Finalizado',
      _ => status,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: highlighted
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StandingsSection extends ConsumerWidget {
  const _StandingsSection({required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final standings = ref.watch(standingsProvider(tournamentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tabla de posiciones',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        standings.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text(
            friendlyErrorMessage(error),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return Text(
                'Todavía no hay equipos inscritos en este torneo.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _StandingsTable(rows: rows),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.rows});

  final List<StandingRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final cellStyle = theme.textTheme.bodySmall;

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(28),
        3: FixedColumnWidth(26),
        4: FixedColumnWidth(26),
        5: FixedColumnWidth(26),
        6: FixedColumnWidth(38),
      },
      children: [
        TableRow(
          children: [
            _cell('#', headerStyle, center: true),
            _cell('Equipo', headerStyle),
            _cell('PJ', headerStyle, center: true),
            _cell('G', headerStyle, center: true),
            _cell('E', headerStyle, center: true),
            _cell('P', headerStyle, center: true),
            _cell('DIF', headerStyle, center: true),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    )
                  : null,
            ),
            children: [
              _cell('${i + 1}', cellStyle, center: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  rows[i].team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _cell('${rows[i].played}', cellStyle, center: true),
              _cell('${rows[i].wins}', cellStyle, center: true),
              _cell('${rows[i].draws}', cellStyle, center: true),
              _cell('${rows[i].losses}', cellStyle, center: true),
              _cell(
                rows[i].difference > 0
                    ? '+${rows[i].difference}'
                    : '${rows[i].difference}',
                cellStyle,
                center: true,
              ),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle? style, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: style,
      ),
    );
  }
}

class _BracketSection extends ConsumerWidget {
  const _BracketSection({required this.tournament, required this.isAdmin});

  final Tournament tournament;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bracket = ref.watch(bracketProvider(tournament.id));
    final standings =
        ref.watch(standingsProvider(tournament.id)).asData?.value ??
        const <StandingRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eliminatorias',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        bracket.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text(
            friendlyErrorMessage(error),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (slots) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: TournamentBracket(slots: slots),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                _StageControls(
                  tournament: tournament,
                  slots: slots,
                  standings: standings,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StageControls extends ConsumerStatefulWidget {
  const _StageControls({
    required this.tournament,
    required this.slots,
    required this.standings,
  });

  final Tournament tournament;
  final List<TournamentSlot> slots;
  final List<StandingRow> standings;

  @override
  ConsumerState<_StageControls> createState() => _StageControlsState();
}

class _StageControlsState extends ConsumerState<_StageControls> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = widget.tournament.stage;
    final next = current.next;

    if (current == TournamentStage.league) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enviar el torneo a eliminatorias',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cuartos necesita 8 equipos, semifinales 4 y la final 2. '
                'Al elegir una fase verás el sorteo antes de confirmar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stage in TournamentStage.knockout)
                    OutlinedButton(
                      onPressed: _busy || _participantsFor(stage) == null
                          ? null
                          : () => _advance(stage),
                      child: Text(stage.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final canShuffle =
        current != TournamentStage.finalStage &&
        (current == TournamentStage.quarterfinal ||
            _winnersOf(TournamentStage.quarterfinal) == null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fase actual: ${current.label}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next == null
                  ? 'El torneo está en la final.'
                  : _participantsFor(next) == null
                  ? 'Termina todos los cruces de ${current.label.toLowerCase()} '
                        'para pasar a ${next.label.toLowerCase()}.'
                  : 'Puedes pasar a ${next.label.toLowerCase()} cuando quieras.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canShuffle)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _shuffle,
                    icon: const Icon(Icons.shuffle),
                    label: Text('Sortear ${current.label.toLowerCase()}'),
                  ),
                if (next != null)
                  FilledButton(
                    onPressed: _busy || _participantsFor(next) == null
                        ? null
                        : () => _advance(next),
                    child: Text('Pasar a ${next.label.toLowerCase()}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Participantes en orden de cuadro para una fase, o `null` si faltan datos.
  List<Team>? _participantsFor(TournamentStage stage) {
    final standings = widget.standings;

    switch (stage) {
      case TournamentStage.quarterfinal:
        if (standings.length < 8) return null;
        final top = standings.take(8).map((row) => row.team).toList();
        return [top[0], top[7], top[1], top[6], top[2], top[5], top[3], top[4]];
      case TournamentStage.semifinal:
        // Si ya hay cuartos, las semis salen de sus ganadores.
        if (_hasSlots(TournamentStage.quarterfinal)) {
          return _winnersOf(TournamentStage.quarterfinal);
        }
        if (standings.length < 4) return null;
        final top = standings.take(4).map((row) => row.team).toList();
        return [top[0], top[3], top[1], top[2]];
      case TournamentStage.finalStage:
        if (_hasSlots(TournamentStage.semifinal)) {
          return _winnersOf(TournamentStage.semifinal);
        }
        if (standings.length < 2) return null;
        final top = standings.take(2).map((row) => row.team).toList();
        return [top[0], top[1]];
      case TournamentStage.league:
        return null;
    }
  }

  bool _hasSlots(TournamentStage stage) {
    return widget.slots.any((slot) => slot.stage == stage);
  }

  /// Ganadores de una fase en orden, o `null` si algún cruce está pendiente.
  List<Team>? _winnersOf(TournamentStage stage) {
    final slots = widget.slots.where((slot) => slot.stage == stage).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    if (slots.isEmpty) return null;

    final winners = <Team>[];
    for (final slot in slots) {
      final winnerId = slot.winnerTeamId;
      if (winnerId == null) return null;
      final team = slot.homeTeam?.id == winnerId
          ? slot.homeTeam
          : slot.awayTeam;
      if (team == null) return null;
      winners.add(team);
    }
    return winners;
  }

  Future<void> _advance(TournamentStage stage) async {
    final participants = _participantsFor(stage);
    if (participants == null) return;

    final allowShuffle =
        stage == TournamentStage.quarterfinal ||
        (stage == TournamentStage.semifinal &&
            _winnersOf(TournamentStage.quarterfinal) == null);

    final chosen = await _previewDialog(
      stage: stage,
      participants: participants,
      allowShuffle: allowShuffle,
    );
    if (chosen == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .advanceStage(
            tournamentId: widget.tournament.id,
            stage: stage,
            participants: chosen,
          );
      ref.invalidate(tournamentProvider(widget.tournament.id));
      ref.invalidate(bracketProvider(widget.tournament.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Torneo enviado a ${stage.label.toLowerCase()}.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shuffle() async {
    final stage = widget.tournament.stage;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .shuffleStage(tournamentId: widget.tournament.id, stage: stage);
      ref.invalidate(bracketProvider(widget.tournament.id));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<Team>?> _previewDialog({
    required TournamentStage stage,
    required List<Team> participants,
    required bool allowShuffle,
  }) async {
    final list = List<Team>.of(participants);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${stage.label}: así quedaría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < list.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${i ~/ 2 + 1}. ${list[i].name} vs ${list[i + 1].name}',
                    ),
                  ),
                if (allowShuffle) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Puedes sortear los cruces antes de confirmar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (allowShuffle)
              TextButton.icon(
                onPressed: () => setDialogState(list.shuffle),
                icon: const Icon(Icons.shuffle),
                label: const Text('Sortear'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    return confirmed == true ? list : null;
  }
}
