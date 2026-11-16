import 'package:flutter/material.dart';

import '../../domain/tournament.dart';
import '../../domain/tournament_slot.dart';

/// Árbol del cuadro eliminatorio: cuartos, semifinales y final.
///
/// Las fases que todavía no se han sorteado se muestran como huecos, para que
/// el administrador vea de antemano cómo quedaría el cuadro.
class TournamentBracket extends StatelessWidget {
  const TournamentBracket({super.key, required this.slots});

  final List<TournamentSlot> slots;

  static const _columnWidth = 164.0;
  static const _height = 300.0;

  @override
  Widget build(BuildContext context) {
    final quarters = _of(TournamentStage.quarterfinal);
    final semis = _of(TournamentStage.semifinal);
    final finals = _of(TournamentStage.finalStage);

    final quarterEntries = quarters.isNotEmpty
        ? [for (final slot in quarters) _Entry.slot(slot)]
        : List<_Entry>.generate(
            4,
            (_) => const _Entry.pending('Por definir', 'Por definir'),
          );

    final semiEntries = semis.isNotEmpty
        ? [for (final slot in semis) _Entry.slot(slot)]
        : quarters.isNotEmpty
        ? [
            const _Entry.pending('Ganador C1', 'Ganador C2'),
            const _Entry.pending('Ganador C3', 'Ganador C4'),
          ]
        : List<_Entry>.generate(
            2,
            (_) => const _Entry.pending('Por definir', 'Por definir'),
          );

    final finalEntries = finals.isNotEmpty
        ? [for (final slot in finals) _Entry.slot(slot)]
        : [
            _Entry.pending(
              semis.isNotEmpty ? 'Ganador S1' : 'Por definir',
              semis.isNotEmpty ? 'Ganador S2' : 'Por definir',
            ),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: _height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StageColumn(
              title: 'Cuartos',
              entries: quarterEntries,
              width: _columnWidth,
            ),
            _StageColumn(
              title: 'Semifinales',
              entries: semiEntries,
              width: _columnWidth,
            ),
            _StageColumn(
              title: 'Final',
              entries: finalEntries,
              width: _columnWidth,
            ),
          ],
        ),
      ),
    );
  }

  List<TournamentSlot> _of(TournamentStage stage) {
    final list = slots.where((slot) => slot.stage == stage).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({
    required this.title,
    required this.entries,
    required this.width,
  });

  final String title;
  final List<_Entry> entries;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 6),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _SlotCard(entry: entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = entry.slot;
    final winner = slot?.winnerTeamId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TeamLine(
            name: entry.homeLabel,
            score: slot?.homeScore,
            isWinner: winner != null && winner == slot?.homeTeam?.id,
          ),
          Divider(
            height: 8,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          _TeamLine(
            name: entry.awayLabel,
            score: slot?.awayScore,
            isWinner: winner != null && winner == slot?.awayTeam?.id,
          ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({required this.name, required this.isWinner, this.score});

  final String name;
  final bool isWinner;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              color: isWinner
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 6),
          Text(
            '$score',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _Entry {
  const _Entry.slot(this.slot) : _home = null, _away = null;

  const _Entry.pending(this._home, this._away) : slot = null;

  final TournamentSlot? slot;
  final String? _home;
  final String? _away;

  String get homeLabel => slot?.homeTeam?.name ?? _home ?? 'Por definir';
  String get awayLabel => slot?.awayTeam?.name ?? _away ?? 'Por definir';
}
