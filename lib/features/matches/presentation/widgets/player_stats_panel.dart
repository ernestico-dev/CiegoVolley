import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';

import '../../../teams/domain/team_member.dart';
import '../../domain/match_action.dart';
import '../../domain/match_draft.dart';

/// Estadísticas del jugador elegido: saque, ataque, defensa y bloqueo, cada
/// una con su botón de éxito y su botón de fallo.
class PlayerStatsPanel extends StatelessWidget {
  const PlayerStatsPanel({
    super.key,
    required this.player,
    required this.teamName,
    required this.draft,
    required this.onRegister,
    required this.onUndo,
    required this.onClose,
  });

  final TeamMember player;
  final String teamName;
  final MatchDraft draft;
  final void Function(MatchAction action, {required MatchActionOutcome outcome})
  onRegister;
  final void Function(MatchAction action, {required MatchActionOutcome outcome})
  onUndo;
  final VoidCallback onClose;

  static IconData iconFor(MatchAction action) {
    return switch (action) {
      MatchAction.serve => Icons.sports_volleyball_outlined,
      MatchAction.attack => Icons.flash_on_outlined,
      MatchAction.defense => Icons.shield_outlined,
      MatchAction.block => Icons.front_hand_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: player.displayName,
                  avatarUrl: player.avatarUrl,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar estadísticas',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final action in MatchAction.values) ...[
              _ActionRow(
                action: action,
                tally: draft.tallyFor(player.userId, action),
                onRegister: (outcome) => onRegister(action, outcome: outcome),
                onUndo: (outcome) => onUndo(action, outcome: outcome),
              ),
              if (action != MatchAction.values.last) const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            Text(
              'Toca para sumar · mantén pulsado para restar',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.tally,
    required this.onRegister,
    required this.onUndo,
  });

  final MatchAction action;
  final MatchTally tally;
  final void Function(MatchActionOutcome outcome) onRegister;
  final void Function(MatchActionOutcome outcome) onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcomes = _outcomesFor(action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Row(
            children: [
              Icon(
                PlayerStatsPanel.iconFor(action),
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  action.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              for (final outcome in outcomes)
                _OutcomeButton(
                  action: action,
                  outcome: outcome,
                  count: _countFor(tally, outcome),
                  onTap: () => onRegister(outcome),
                  onLongPress: () => onUndo(outcome),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static List<MatchActionOutcome> _outcomesFor(MatchAction action) {
    return switch (action) {
      MatchAction.serve => const [
        MatchActionOutcome.positive,
        MatchActionOutcome.error,
        MatchActionOutcome.neutral,
      ],
      MatchAction.attack => const [
        MatchActionOutcome.positive,
        MatchActionOutcome.error,
        MatchActionOutcome.blocked,
        MatchActionOutcome.neutral,
      ],
      MatchAction.defense => const [
        MatchActionOutcome.positive,
        MatchActionOutcome.error,
      ],
      MatchAction.block => const [
        MatchActionOutcome.positive,
        MatchActionOutcome.error,
        MatchActionOutcome.neutral,
      ],
    };
  }

  static int _countFor(MatchTally tally, MatchActionOutcome outcome) {
    return switch (outcome) {
      MatchActionOutcome.positive => tally.successes,
      MatchActionOutcome.error => tally.failures,
      MatchActionOutcome.neutral => tally.neutrals,
      MatchActionOutcome.blocked => tally.blocked,
    };
  }
}

class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({
    required this.action,
    required this.outcome,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  final MatchAction action;
  final MatchActionOutcome outcome;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = switch (outcome) {
      MatchActionOutcome.positive => scheme.secondaryContainer,
      MatchActionOutcome.error => scheme.errorContainer,
      MatchActionOutcome.neutral => scheme.surfaceContainerHighest,
      MatchActionOutcome.blocked => scheme.tertiaryContainer,
    };
    final foreground = switch (outcome) {
      MatchActionOutcome.positive => scheme.onSecondaryContainer,
      MatchActionOutcome.error => scheme.onErrorContainer,
      MatchActionOutcome.neutral => scheme.onSurface,
      MatchActionOutcome.blocked => scheme.onTertiaryContainer,
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (outcome) {
                  MatchActionOutcome.positive => Icons.check_circle_outline,
                  MatchActionOutcome.error => Icons.cancel_outlined,
                  MatchActionOutcome.neutral => Icons.remove_circle_outline,
                  MatchActionOutcome.blocked => Icons.block_outlined,
                },
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 4),
              Text(
                _labelFor(action, outcome),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelFor(MatchAction action, MatchActionOutcome outcome) {
    return switch ((action, outcome)) {
      (MatchAction.serve, MatchActionOutcome.positive) => 'Ace',
      (MatchAction.attack, MatchActionOutcome.positive) => 'Punto',
      (MatchAction.attack, MatchActionOutcome.blocked) => 'Bloqueado',
      (MatchAction.defense, MatchActionOutcome.positive) => 'Positivo',
      (MatchAction.block, MatchActionOutcome.positive) => 'Punto',
      (_, MatchActionOutcome.error) => 'Error',
      (_, MatchActionOutcome.neutral) => 'Neutro',
      _ => 'Resultado',
    };
  }
}
