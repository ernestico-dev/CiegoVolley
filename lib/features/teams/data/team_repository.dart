import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/team.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(supabaseClientProvider)),
);

/// Equipos visibles para el usuario. Se refresca con `ref.invalidate`.
final teamsProvider = FutureProvider.autoDispose<List<Team>>((ref) {
  return ref.watch(teamRepositoryProvider).fetchTeams();
});

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  Future<List<Team>> fetchTeams() async {
    final rows = await _client
        .from('teams')
        .select()
        .order('created_at', ascending: false);

    return rows.map(Team.fromMap).toList();
  }

  Future<void> createTeam({
    required String name,
    required String category,
    String? season,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }

    await _client.from('teams').insert({
      'owner_id': user.id,
      'name': name.trim(),
      'category': category,
      if (season != null && season.trim().isNotEmpty) 'season': season.trim(),
    });
  }
}
