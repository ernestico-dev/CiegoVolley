import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/tournament.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepository(ref.watch(supabaseClientProvider)),
);

/// Torneos publicados en la plataforma.
final tournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).fetchTournaments();
});

class TournamentRepository {
  TournamentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Tournament>> fetchTournaments() async {
    final rows = await _client
        .from('tournaments')
        .select()
        .order('starts_on', ascending: true, nullsFirst: false);

    return rows.map(Tournament.fromMap).toList();
  }
}
