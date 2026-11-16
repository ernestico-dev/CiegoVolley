import 'package:flutter/material.dart';

import '../../domain/match_draft.dart';

/// Marcador con un botón de sumar y otro de quitar en cada lado.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.draft,
    required this.onHomeAdd,
    required this.onHomeRemove,
    required this.onAwayAdd,
    required this.onAwayRemove,
  });

  final MatchDraft draft;
  final VoidCallback onHomeAdd;
  final VoidCallback onHomeRemove;
  final VoidCallback onAwayAdd;
  final VoidCallback onAwayRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
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
