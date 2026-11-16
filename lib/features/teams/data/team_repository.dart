import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../tournaments/domain/team_tournament.dart';
import '../domain/team.dart';
import '../domain/team_member.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(supabaseClientProvider)),
);

/// Equipos visibles para el usuario. Se refresca con `ref.invalidate`.
final teamsProvider = FutureProvider.autoDispose<List<Team>>((ref) {
  return ref.watch(teamRepositoryProvider).fetchTeams();
}, retry: noRetry);

/// Detalle de un equipo.
final teamProvider = FutureProvider.autoDispose.family<Team, String>((ref, id) {
  return ref.watch(teamRepositoryProvider).fetchTeam(id);
}, retry: noRetry);

/// Integrantes de un equipo.
final teamMembersProvider = FutureProvider.autoDispose
    .family<List<TeamMember>, String>((ref, teamId) {
      return ref.watch(teamRepositoryProvider).fetchMembers(teamId);
    }, retry: noRetry);

/// Torneos en los que está inscrito un equipo.
final teamTournamentsProvider = FutureProvider.autoDispose
    .family<List<TeamTournament>, String>((ref, teamId) {
      return ref.watch(teamRepositoryProvider).fetchTeamTournaments(teamId);
    }, retry: noRetry);

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }
    return user.id;
  }

  Future<List<Team>> fetchTeams() async {
    final rows = await _client
        .from('teams')
        .select()
        .order('created_at', ascending: false);

    return rows.map(Team.fromMap).toList();
  }

  Future<Team> fetchTeam(String id) async {
    final row = await _client.from('teams').select().eq('id', id).single();
    return Team.fromMap(row);
  }

  Future<void> createTeam({
    required String name,
    required String category,
    String? season,
  }) async {
    final userId = _userId;

    final team = await _client
        .from('teams')
        .insert({
          'owner_id': userId,
          'name': name.trim(),
          'category': category,
          'season': _cleanSeason(season),
        })
        .select('id')
        .single();

    // El creador forma parte del equipo desde el primer momento.
    // El trigger `add_team_owner_as_member` hace lo mismo, así que se ignora
    // el duplicado si ya lo insertó.
    await _client
        .from('team_members')
        .upsert(
          {
            'team_id': team['id'] as String,
            'user_id': userId,
            'role': 'player',
          },
          ignoreDuplicates: true,
          onConflict: 'team_id,user_id',
        );
  }

  /// Solo el creador del equipo puede llamar a esto (lo garantiza RLS).
  Future<void> updateTeam({
    required String id,
    required String name,
    required String category,
    String? season,
  }) async {
    await _client
        .from('teams')
        .update({
          'name': name.trim(),
          'category': category,
          'season': _cleanSeason(season),
        })
        .eq('id', id);
  }

  /// Solo el creador puede eliminar el equipo (lo impone RLS).
  Future<void> deleteTeam(String id) async {
    await _client.from('teams').delete().eq('id', id);
  }

  Future<List<TeamMember>> fetchMembers(String teamId) async {
    final rows = await _client
        .from('team_members')
        .select(
          'role, joined_at, '
          'profile:profiles!team_members_user_id_fkey'
          '(id, full_name, email, avatar_url)',
        )
        .eq('team_id', teamId)
        .order('joined_at');

    return rows.map(TeamMember.fromMap).toList();
  }

  /// Busca usuarios registrados por nombre, para el selector de integrantes.
  ///
  /// `excludeUserIds` deja fuera al creador y a quienes ya están en el equipo.
  Future<List<ProfileSummary>> searchProfiles(
    String query, {
    Set<String> excludeUserIds = const {},
    int limit = 10,
  }) async {
    final term = query.trim();
    if (term.length < 2) return const [];

    var filter = _client
        .from('profiles')
        .select('id, full_name, email, avatar_url')
        .ilike('full_name', '%${_escapeLike(term)}%');

    if (excludeUserIds.isNotEmpty) {
      filter = filter.not('id', 'in', '(${excludeUserIds.join(',')})');
    }

    final rows = await filter.order('full_name').limit(limit);
    return rows.map(ProfileSummary.fromMap).toList();
  }

  Future<void> addMember({
    required String teamId,
    required String userId,
  }) async {
    await _client.from('team_members').insert({
      'team_id': teamId,
      'user_id': userId,
    });
  }

  Future<void> removeMember({
    required String teamId,
    required String userId,
  }) async {
    await _client
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }

  Future<List<TeamTournament>> fetchTeamTournaments(String teamId) async {
    final rows = await _client
        .from('tournament_teams')
        .select(
          'status, registered_at, '
          'tournament:tournaments!tournament_teams_tournament_id_fkey'
          '(id, name, venue, starts_on, ends_on, status)',
        )
        .eq('team_id', teamId)
        .order('registered_at');

    return rows.map(TeamTournament.fromMap).toList();
  }

  Future<void> joinTournament({
    required String teamId,
    required String tournamentId,
  }) async {
    await _client.from('tournament_teams').insert({
      'team_id': teamId,
      'tournament_id': tournamentId,
    });
  }

  Future<void> leaveTournament({
    required String teamId,
    required String tournamentId,
  }) async {
    await _client
        .from('tournament_teams')
        .delete()
        .eq('team_id', teamId)
        .eq('tournament_id', tournamentId);
  }

  static String? _cleanSeason(String? season) {
    final value = season?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Escapa los comodines de `LIKE` para que el texto se busque tal cual.
  static String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
