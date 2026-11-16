import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../teams/domain/team.dart';
import '../domain/match_draft.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(supabaseClientProvider)),
);

/// Equipos inscritos en un torneo (los que pueden jugar en él).
final tournamentTeamsProvider = FutureProvider.autoDispose
    .family<List<Team>, String>((ref, tournamentId) {
      return ref
          .watch(matchRepositoryProvider)
          .fetchTournamentTeams(tournamentId);
    }, retry: noRetry);

class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;

  Future<List<Team>> fetchTournamentTeams(String tournamentId) async {
    final rows = await _client
        .from('tournament_teams')
        .select(
          'team:teams!tournament_teams_team_id_fkey'
          '(id, name, category, owner_id, season, created_at)',
        )
        .eq('tournament_id', tournamentId)
        .neq('status', 'withdrawn')
        .order('registered_at');

    return rows
        .map((row) => Team.fromMap(row['team'] as Map<String, dynamic>))
        .toList();
  }

  /// Guarda el partido con el marcador y las estadísticas por jugador.
  Future<void> saveMatch(MatchDraft draft) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }

    final match = await _client
        .from('matches')
        .insert({
          'tournament_id': draft.tournament.id,
          'home_team_id': draft.homeTeam.id,
          'away_team_id': draft.awayTeam.id,
          'home_score': draft.homeScore,
          'away_score': draft.awayScore,
          'status': 'finished',
          'created_by': user.id,
        })
        .select('id')
        .single();

    final matchId = match['id'] as String;

    final rows = <Map<String, dynamic>>[
      for (final entry in draft.tallies.entries)
        if (entry.value.total > 0)
          {
            'match_id': matchId,
            'team_id': draft.teamIdOf(entry.key.userId),
            'user_id': entry.key.userId,
            'action': entry.key.action.dbValue,
            'successes': entry.value.successes,
            'failures': entry.value.failures,
          },
    ];

    if (rows.isEmpty) return;

    await _client.from('match_player_stats').insert(rows);
  }
}
