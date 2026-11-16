import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../matches/domain/match_action.dart';
import '../../teams/domain/team.dart';
import '../domain/action_leader.dart';
import '../domain/global_stats.dart';
import '../domain/player_stats.dart';
import '../domain/team_stats.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(ref.watch(supabaseClientProvider)),
);

/// Estadísticas globales de la plataforma (jugadores, equipos y acciones).
final globalStatsProvider = FutureProvider.autoDispose<GlobalStats>((ref) {
  return ref.watch(statsRepositoryProvider).fetchGlobalStats();
}, retry: noRetry);

/// Intentos mínimos para entrar en el ranking de una acción concreta.
const _minAttemptsForLeader = 3;

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<GlobalStats> fetchGlobalStats() async {
    final results = await Future.wait([
      _client
          .from('match_player_stats')
          .select(
            'match_id, team_id, user_id, action, successes, failures, '
            'profile:profiles!match_player_stats_user_id_fkey(full_name, email)',
          ),
      _client
          .from('matches')
          .select(
            'id, tournament_id, home_team_id, away_team_id, '
            'home_score, away_score',
          ),
      _client.from('teams').select(),
    ]);

    final statRows = results[0];
    final matchRows = results[1];
    final teamRows = results[2];

    final teams = <String, Team>{
      for (final row in teamRows) (row['id'] as String): Team.fromMap(row),
    };

    final winners = <String, String?>{};
    final matchTournaments = <String, String>{};

    for (final row in matchRows) {
      final id = row['id'] as String;
      final homeScore = (row['home_score'] as num?)?.toInt() ?? 0;
      final awayScore = (row['away_score'] as num?)?.toInt() ?? 0;

      winners[id] = homeScore == awayScore
          ? null
          : homeScore > awayScore
          ? row['home_team_id'] as String
          : row['away_team_id'] as String;
      matchTournaments[id] = row['tournament_id'] as String;
    }

    final players = <String, _PlayerAccumulator>{};
    final actionTotals = <MatchAction, int>{
      for (final a in MatchAction.values) a: 0,
    };
    final actionByPlayer = <MatchAction, Map<String, _ActionAccumulator>>{
      for (final a in MatchAction.values) a: {},
    };
    final countedMatches = <String>{};

    for (final row in statRows) {
      final matchId = row['match_id'] as String;
      final userId = row['user_id'] as String;
      final action = MatchAction.fromDb(row['action'] as String? ?? '');
      if (action == null) continue;

      final successes = (row['successes'] as num?)?.toInt() ?? 0;
      final failures = (row['failures'] as num?)?.toInt() ?? 0;

      final profile = row['profile'] as Map<String, dynamic>? ?? const {};
      final name = _displayName(profile);

      final player = players.putIfAbsent(
        userId,
        () => _PlayerAccumulator(userId: userId, name: name),
      );
      player.successes += successes;
      player.failures += failures;

      actionTotals[action] = (actionTotals[action] ?? 0) + successes + failures;

      final byPlayer = actionByPlayer[action]!;
      final actionAcc = byPlayer.putIfAbsent(
        userId,
        () => _ActionAccumulator(userId: userId, name: name, action: action),
      );
      actionAcc.successes += successes;
      actionAcc.failures += failures;

      // Un partido cuenta una sola vez por jugador.
      if (!countedMatches.add('$userId|$matchId')) continue;
      player.matchesPlayed++;

      final winner = winners[matchId];
      final teamId = row['team_id'] as String;
      if (winner != null && winner == teamId) player.matchesWon++;

      final tournamentId = matchTournaments[matchId];
      if (tournamentId != null) player.tournaments.add(tournamentId);
    }

    final playerList =
        players.values
            .map(
              (p) => PlayerStats(
                userId: p.userId,
                name: p.name,
                successes: p.successes,
                failures: p.failures,
                matchesPlayed: p.matchesPlayed,
                matchesWon: p.matchesWon,
                tournaments: p.tournaments.length,
              ),
            )
            .toList()
          ..sort(PlayerStats.compare);

    final leaders = <MatchAction, ActionLeader>{};
    for (final action in MatchAction.values) {
      final candidates =
          actionByPlayer[action]!.values
              .where((a) => a.successes + a.failures >= _minAttemptsForLeader)
              .map(
                (a) => ActionLeader(
                  action: a.action,
                  userId: a.userId,
                  name: a.name,
                  successes: a.successes,
                  failures: a.failures,
                ),
              )
              .toList()
            ..sort(ActionLeader.compare);

      if (candidates.isNotEmpty) leaders[action] = candidates.first;
    }

    final teamStats = <String, _TeamAccumulator>{};
    for (final row in matchRows) {
      final homeId = row['home_team_id'] as String;
      final awayId = row['away_team_id'] as String;
      final homeScore = (row['home_score'] as num?)?.toInt() ?? 0;
      final awayScore = (row['away_score'] as num?)?.toInt() ?? 0;

      final home = teamStats.putIfAbsent(
        homeId,
        () => _TeamAccumulator(team: teams[homeId] ?? _unknownTeam(homeId)),
      );
      final away = teamStats.putIfAbsent(
        awayId,
        () => _TeamAccumulator(team: teams[awayId] ?? _unknownTeam(awayId)),
      );

      home.played++;
      away.played++;

      if (homeScore == awayScore) {
        home.draws++;
        away.draws++;
      } else if (homeScore > awayScore) {
        home.wins++;
        away.losses++;
      } else {
        away.wins++;
        home.losses++;
      }
    }

    final teamList =
        teamStats.values
            .map(
              (t) => TeamStats(
                team: t.team,
                played: t.played,
                wins: t.wins,
                draws: t.draws,
                losses: t.losses,
              ),
            )
            .toList()
          ..sort(TeamStats.compare);

    final totalSuccesses = players.values.fold<int>(
      0,
      (sum, p) => sum + p.successes,
    );
    final totalFailures = players.values.fold<int>(
      0,
      (sum, p) => sum + p.failures,
    );

    return GlobalStats(
      players: playerList,
      teams: teamList,
      leaders: leaders,
      actionTotals: actionTotals,
      totalSuccesses: totalSuccesses,
      totalFailures: totalFailures,
      matchCount: matchRows.length,
      tournamentCount: matchTournaments.values.toSet().length,
    );
  }

  static String _displayName(Map<String, dynamic> profile) {
    final fullName = (profile['full_name'] as String?)?.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final email = (profile['email'] as String?)?.trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Jugador';
  }

  static Team _unknownTeam(String id) {
    return Team(
      id: id,
      name: 'Equipo eliminado',
      category: 'Sin categoría',
      ownerId: '',
    );
  }
}

class _PlayerAccumulator {
  _PlayerAccumulator({required this.userId, required this.name});

  final String userId;
  final String name;
  int successes = 0;
  int failures = 0;
  int matchesPlayed = 0;
  int matchesWon = 0;
  final Set<String> tournaments = {};
}

class _ActionAccumulator {
  _ActionAccumulator({
    required this.userId,
    required this.name,
    required this.action,
  });

  final String userId;
  final String name;
  final MatchAction action;
  int successes = 0;
  int failures = 0;
}

class _TeamAccumulator {
  _TeamAccumulator({required this.team});

  final Team team;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
}
