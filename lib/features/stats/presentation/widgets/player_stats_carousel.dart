import 'package:flutter/material.dart';

import '../../../matches/domain/match_action.dart';
import '../../domain/player_stats.dart';
import 'action_colors.dart';
import 'donut_chart.dart';

class PlayerStatsCarousel extends StatefulWidget {
  const PlayerStatsCarousel({super.key, required this.players});

  final List<PlayerStats> players;

  @override
  State<PlayerStatsCarousel> createState() => PlayerStatsCarouselState();
}

class PlayerStatsCarouselState extends State<PlayerStatsCarousel> {
  final _searchController = TextEditingController();
  final _pageController = PageController();
  String _query = '';
  int _index = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<PlayerStats> get _filtered {
    final term = _normalize(_query.trim());
    if (term.isEmpty) return widget.players;
    return widget.players
        .where((player) => _normalize(player.name).contains(term))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = _filtered;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Estadísticas de jugadores',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (players.isNotEmpty)
                    Text(
                      '${_index + 1} de ${players.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 4),
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 8,
                ),
                child: Text(
                  widget.players.isEmpty
                      ? 'Aún no hay acciones registradas por jugador.'
                      : 'No encontramos jugadores con ese nombre.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 300,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Jugador anterior',
                      onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: players.length,
                        onPageChanged: (value) =>
                            setState(() => _index = value),
                        itemBuilder: (context, index) =>
                            PlayerStatsPage(player: players[index]),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Jugador siguiente',
                      onPressed: _index >= players.length - 1
                          ? null
                          : () => _goTo(_index + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _index = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Minúsculas y sin tildes, para que "jose" encuentre a "José".
  static String _normalize(String value) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final position = from.indexOf(char);
      buffer.write(position >= 0 ? to[position] : char);
    }
    return buffer.toString();
  }
}

class PlayerStatsPage extends StatelessWidget {
  const PlayerStatsPage({super.key, required this.player});

  final PlayerStats player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final best = player.bestAction;

    return Column(
      children: [
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${player.matchesPlayed} partidos · ${player.matchesWon} ganados · '
          '${player.tournaments} torneos',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Aciertos y fallos',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DonutChart(
                    size: 96,
                    slices: [
                      DonutSlice(
                        label: 'Aciertos',
                        value: player.successes,
                        color: scheme.primary,
                      ),
                      DonutSlice(
                        label: 'Fallos',
                        value: player.failures,
                        color: scheme.error,
                      ),
                    ],
                    centerValue: '${player.successPercent}%',
                    centerLabel: 'éxito',
                  ),
                  const SizedBox(height: 6),
                  LegendItem(
                    color: scheme.primary,
                    label: 'Aciertos',
                    value: '${player.successes}',
                  ),
                  LegendItem(
                    color: scheme.error,
                    label: 'Fallos',
                    value: '${player.failures}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Acciones',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DonutChart(
                    size: 96,
                    slices: [
                      for (final action in MatchAction.values)
                        DonutSlice(
                          label: action.label,
                          value: player.tallyFor(action).total,
                          color: actionColor(scheme, action),
                        ),
                    ],
                    centerValue: '${player.attempts}',
                    centerLabel: 'acciones',
                  ),
                  const SizedBox(height: 6),
                  for (final action in MatchAction.values)
                    LegendItem(
                      color: actionColor(scheme, action),
                      label: action.label,
                      value: '${player.tallyFor(action).total}',
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            best == null
                ? 'Sin acciones registradas'
                : 'Mejor fundamento: ${best.label} '
                      '(${player.tallyFor(best).successPercent}%)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            height: 9,
            width: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
