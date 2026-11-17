import 'package:flutter/material.dart';

import '../../domain/match_draft.dart';

/// Marcador con un botón de sumar y otro de quitar en cada lado.
///
/// Arriba muestra el set en juego y los sets ya cerrados.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.draft,
    required this.onHomeAdd,
    required this.onHomeRemove,
    required this.onAwayAdd,
    required this.onAwayRemove,
    this.onUndoSet,
  });

  final MatchDraft draft;
  final VoidCallback onHomeAdd;
  final VoidCallback onHomeRemove;
  final VoidCallback onAwayAdd;
  final VoidCallback onAwayRemove;
  final VoidCallback? onUndoSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Set ${draft.currentSet} de ${draft.setsCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sets ${draft.homeSetsWon} - ${draft.awaySetsWon}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (draft.completedSets.isNotEmpty && onUndoSet != null)
                  IconButton(
                    tooltip: 'Deshacer último set',
                    visualDensity: VisualDensity.compact,
                    onPressed: onUndoSet,
                    icon: const Icon(Icons.undo, size: 18),
                  ),
              ],
            ),
            if (draft.completedSets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < draft.completedSets.length; i++)
                      _SetChip(set: draft.completedSets[i], number: i + 1),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _Side(
                    name: draft.homeTeam.name,
                    score: draft.homeScore,
                    highlight: draft.homeScore >= draft.awayScore,
                    onAdd: onHomeAdd,
                    onRemove: onHomeRemove,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ':',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: _Side(
                    name: draft.awayTeam.name,
                    score: draft.awayScore,
                    highlight: draft.awayScore > draft.homeScore,
                    onAdd: onAwayAdd,
                    onRemove: onAwayRemove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({required this.set, required this.number});

  final MatchSet set;
  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final homeWon = set.isHomeWin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: homeWon ? scheme.primaryContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Set $number: ${set.home}-${set.away}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: homeWon
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.score,
    required this.highlight,
    required this.onAdd,
    required this.onRemove,
  });

  final String name;
  final int score;
  final bool highlight;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Quitar punto',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$score',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: highlight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sumar punto',
              visualDensity: VisualDensity.compact,
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
