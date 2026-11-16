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
}, retry: noRetry);

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

  /// Solo el administrador puede crear torneos (lo impone RLS).
  Future<void> createTournament({
    required String name,
    String? venue,
    DateTime? startsOn,
    DateTime? endsOn,
    required String status,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }

    await _client.from('tournaments').insert({
      'owner_id': user.id,
      'name': name.trim(),
      ..._payload(
        venue: venue,
        startsOn: startsOn,
        endsOn: endsOn,
        status: status,
      ),
    });
  }

  /// Solo el administrador puede editar torneos (lo impone RLS).
  Future<void> updateTournament({
    required String id,
    required String name,
    String? venue,
    DateTime? startsOn,
    DateTime? endsOn,
    required String status,
  }) async {
    await _client
        .from('tournaments')
        .update({
          'name': name.trim(),
          ..._payload(
            venue: venue,
            startsOn: startsOn,
            endsOn: endsOn,
            status: status,
          ),
        })
        .eq('id', id);
  }

  /// Solo el administrador puede eliminar torneos (lo impone RLS).
  Future<void> deleteTournament(String id) async {
    await _client.from('tournaments').delete().eq('id', id);
  }

  Map<String, dynamic> _payload({
    required String? venue,
    required DateTime? startsOn,
    required DateTime? endsOn,
    required String status,
  }) {
    final place = venue?.trim();

    return {
      'venue': (place == null || place.isEmpty) ? null : place,
      'starts_on': startsOn == null ? null : _date(startsOn),
      'ends_on': endsOn == null ? null : _date(endsOn),
      'status': status,
    };
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
