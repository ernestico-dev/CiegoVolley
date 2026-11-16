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
  final void Function(MatchAction action, {required bool success}) onRegister;
  final void Function(MatchAction action, {required bool success}) onUndo;
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
                onSuccess: () => onRegister(action, success: true),
                onFailure: () => onRegister(action, success: false),
                onUndoSuccess: () => onUndo(action, success: true),
                onUndoFailure: () => onUndo(action, success: false),
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
    required this.onSuccess,
    required this.onFailure,
    required this.onUndoSuccess,
    required this.onUndoFailure,
  });

  final MatchAction action;
  final MatchTally tally;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onUndoSuccess;
  final VoidCallback onUndoFailure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 96,
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
          child: _TallyButton(
            success: true,
            count: tally.successes,
            onTap: onSuccess,
            onLongPress: onUndoSuccess,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _TallyButton(
            success: false,
            count: tally.failures,
            onTap: onFailure,
            onLongPress: onUndoFailure,
          ),
        ),
      ],
    );
  }
}

class _TallyButton extends StatelessWidget {
  const _TallyButton({
    required this.success,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  final bool success;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = success
        ? scheme.secondaryContainer
        : scheme.errorContainer;
    final foreground = success
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 4),
              Text(
                success ? 'Éxito' : 'Fallo',
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
}
