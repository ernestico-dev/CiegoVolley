import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/match_draft.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(supabaseClientProvider)),
);

class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;

  /// Guarda el partido con el marcador y las estadísticas por jugador.
  ///
  /// Si el torneo está en eliminatorias, enlaza el partido con su cruce del
  /// cuadro para que el ganador avance de ronda.
  Future<void> saveMatch(MatchDraft draft) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }

    final stage = draft.tournament.stage;

    final match = await _client
        .from('matches')
        .insert({
          'tournament_id': draft.tournament.id,
          'home_team_id': draft.homeTeam.id,
          'away_team_id': draft.awayTeam.id,
          // El resultado del partido son los sets ganados.
          'home_score': draft.homeSetsWon,
          'away_score': draft.awaySetsWon,
          'sets_count': draft.setsCount,
          'sets': [for (final set in draft.completedSets) set.toJson()],
          'status': 'finished',
          'stage': stage.dbValue,
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
            'neutrals': entry.value.neutrals,
            'blocked': entry.value.blocked,
          },
    ];

    if (rows.isNotEmpty) {
      await _client.from('match_player_stats').insert(rows);
    }

    if (!stage.isKnockout) return;

    final home = draft.homeTeam.id;
    final away = draft.awayTeam.id;

    final slot = await _client
        .from('tournament_slots')
        .select('id')
        .eq('tournament_id', draft.tournament.id)
        .eq('stage', stage.dbValue)
        .isFilter('match_id', null)
        .or(
          'and(home_team_id.eq.$home,away_team_id.eq.$away),'
          'and(home_team_id.eq.$away,away_team_id.eq.$home)',
        )
        .maybeSingle();

    if (slot == null) return;

    await _client
        .from('tournament_slots')
        .update({'match_id': matchId})
        .eq('id', slot['id'] as String);
  }
}
