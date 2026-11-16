import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';

import '../../../teams/domain/team_member.dart';
import '../../domain/match_draft.dart';

/// Cancha horizontal con el equipo local a la izquierda y el visitante a la
/// derecha. Cada mitad tiene seis huecos (tres filas de dos).
class VolleyballCourt extends StatelessWidget {
  const VolleyballCourt({
    super.key,
    required this.draft,
    required this.selectedUserId,
    required this.onSelect,
  });

  final MatchDraft draft;
  final String? selectedUserId;
  final ValueChanged<TeamMember> onSelect;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F7D4F), Color(0xFF1F5C39)],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _Half(
                players: draft.homePlayers,
                selectedUserId: selectedUserId,
                onSelect: onSelect,
              ),
            ),
            const _Net(),
            Expanded(
              child: _Half(
                players: draft.awayPlayers,
                selectedUserId: selectedUserId,
                onSelect: onSelect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Net extends StatelessWidget {
  const _Net();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.players,
    required this.selectedUserId,
    required this.onSelect,
  });

  final List<TeamMember> players;
  final String? selectedUserId;
  final ValueChanged<TeamMember> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 2; column++)
                  Expanded(child: _buildSlot(row * 2 + column)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSlot(int index) {
    if (index >= players.length) return const _EmptySlot();

    final player = players[index];
    return _PlayerSlot(
      player: player,
      selected: player.userId == selectedUserId,
      onTap: () => onSelect(player),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final TeamMember player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onSurface
        : Colors.white.withValues(alpha: 0.95);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserAvatar(
                  name: player.displayName,
                  avatarUrl: player.avatarUrl,
                  radius: 12,
                  backgroundColor: selected
                      ? theme.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.2),
                  foregroundColor: selected
                      ? theme.colorScheme.onPrimary
                      : Colors.white,
                ),
                const SizedBox(height: 2),
                Text(
                  _firstName(player.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _firstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
    );
  }
}
