import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/public_images.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../teams/domain/team.dart';
import '../domain/match_result.dart';
import '../domain/standing_row.dart';
import '../domain/tournament.dart';
import '../domain/tournament_slot.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepository(ref.watch(supabaseClientProvider)),
);

/// Torneos publicados en la plataforma.
final tournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).fetchTournaments();
}, retry: noRetry);

/// Un torneo concreto.
final tournamentProvider = FutureProvider.autoDispose
    .family<Tournament, String>((ref, id) {
      return ref.watch(tournamentRepositoryProvider).fetchTournament(id);
    }, retry: noRetry);

/// Equipos inscritos en un torneo.
final tournamentTeamsProvider = FutureProvider.autoDispose
    .family<List<Team>, String>((ref, tournamentId) {
      return ref
          .watch(tournamentRepositoryProvider)
          .fetchTournamentTeams(tournamentId);
    }, retry: noRetry);

/// Partidos guardados de un torneo.
final tournamentMatchesProvider = FutureProvider.autoDispose
    .family<List<MatchResult>, String>((ref, tournamentId) {
      return ref.watch(tournamentRepositoryProvider).fetchMatches(tournamentId);
    }, retry: noRetry);

/// Tabla de posiciones calculada a partir de los partidos de liga.
final standingsProvider = FutureProvider.autoDispose
    .family<List<StandingRow>, String>((ref, tournamentId) async {
      final teams = await ref.watch(
        tournamentTeamsProvider(tournamentId).future,
      );
      final matches = await ref.watch(
        tournamentMatchesProvider(tournamentId).future,
      );

      final rows = {for (final team in teams) team.id: StandingRow(team: team)};

      for (final match in matches.where((m) => m.stage == 'league')) {
        final home = rows[match.homeTeamId];
        final away = rows[match.awayTeamId];
        if (home == null || away == null) continue;

        home.played++;
        away.played++;
        home.pointsFor += match.homeScore;
        home.pointsAgainst += match.awayScore;
        away.pointsFor += match.awayScore;
        away.pointsAgainst += match.homeScore;

        if (match.isDraw) {
          home.draws++;
          away.draws++;
        } else if (match.homeScore > match.awayScore) {
          home.wins++;
          away.losses++;
        } else {
          away.wins++;
          home.losses++;
        }
      }

      return rows.values.toList()..sort(StandingRow.compare);
    }, retry: noRetry);

/// Cruces del cuadro eliminatorio.
final bracketProvider = FutureProvider.autoDispose
    .family<List<TournamentSlot>, String>((ref, tournamentId) {
      return ref.watch(tournamentRepositoryProvider).fetchBracket(tournamentId);
    }, retry: noRetry);

class TournamentRepository {
  TournamentRepository(this._client);

  final SupabaseClient _client;
  final _random = Random();

  Future<List<Tournament>> fetchTournaments() async {
    final rows = await _client
        .from('tournaments')
        .select()
        .order('starts_on', ascending: true, nullsFirst: false);

    return rows.map(Tournament.fromMap).toList();
  }

  Future<Tournament> fetchTournament(String id) async {
    final row = await _client
        .from('tournaments')
        .select()
        .eq('id', id)
        .single();
    return Tournament.fromMap(row);
  }

  Future<List<Team>> fetchTournamentTeams(String tournamentId) async {
    final rows = await _client
        .from('tournament_teams')
        .select(
          'team:teams!tournament_teams_team_id_fkey'
          '(id, name, category, owner_id, season, logo_url, created_at)',
        )
        .eq('tournament_id', tournamentId)
        .neq('status', 'withdrawn')
        .order('registered_at');

    return rows
        .map((row) => Team.fromMap(row['team'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchResult>> fetchMatches(String tournamentId) async {
    final rows = await _client
        .from('matches')
        .select('id, home_team_id, away_team_id, home_score, away_score, stage')
        .eq('tournament_id', tournamentId)
        .order('played_at');

    return rows.map(MatchResult.fromMap).toList();
  }

  Future<List<TournamentSlot>> fetchBracket(String tournamentId) async {
    final rows = await _client
        .from('tournament_slots')
        .select(
          'id, stage, position, match_id, '
          'home:teams!tournament_slots_home_team_id_fkey'
          '(id, name, category, owner_id, season, created_at), '
          'away:teams!tournament_slots_away_team_id_fkey'
          '(id, name, category, owner_id, season, created_at), '
          'match:matches!tournament_slots_match_id_fkey(home_score, away_score)',
        )
        .eq('tournament_id', tournamentId)
        .order('position');

    return rows.map(TournamentSlot.fromMap).toList();
  }

  /// Crea los cruces de una fase y adelanta el torneo a esa fase.
  ///
  /// `participants` va en orden de cuadro: [local1, visitante1, local2, ...].
  Future<void> advanceStage({
    required String tournamentId,
    required TournamentStage stage,
    required List<Team> participants,
  }) async {
    if (participants.length < 2 || participants.length.isOdd) {
      throw StateError('Se necesitan parejas completas para la eliminatoria.');
    }

    await _client
        .from('tournament_slots')
        .delete()
        .eq('tournament_id', tournamentId)
        .eq('stage', stage.dbValue);

    final slots = <Map<String, dynamic>>[
      for (var i = 0; i < participants.length; i += 2)
        {
          'tournament_id': tournamentId,
          'stage': stage.dbValue,
          'position': i ~/ 2 + 1,
          'home_team_id': participants[i].id,
          'away_team_id': participants[i + 1].id,
        },
    ];

    await _client.from('tournament_slots').insert(slots);
    await _client
        .from('tournaments')
        .update({'stage': stage.dbValue})
        .eq('id', tournamentId);
  }

  /// Sortea los cruces de una fase que todavía no tiene resultados.
  Future<void> shuffleStage({
    required String tournamentId,
    required TournamentStage stage,
  }) async {
    final rows = await _client
        .from('tournament_slots')
        .select('id, home_team_id, away_team_id')
        .eq('tournament_id', tournamentId)
        .eq('stage', stage.dbValue)
        .isFilter('match_id', null)
        .order('position');

    if (rows.length < 2) return;

    final teamIds = <String>[
      for (final row in rows) ...[
        if (row['home_team_id'] != null) row['home_team_id'] as String,
        if (row['away_team_id'] != null) row['away_team_id'] as String,
      ],
    ];

    if (teamIds.length < 2) return;
    teamIds.shuffle(_random);

    for (var i = 0; i < rows.length; i++) {
      await _client
          .from('tournament_slots')
          .update({
            'home_team_id': i * 2 < teamIds.length ? teamIds[i * 2] : null,
            'away_team_id': i * 2 + 1 < teamIds.length
                ? teamIds[i * 2 + 1]
                : null,
          })
          .eq('id', rows[i]['id'] as String);
    }
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

  /// Sube la imagen del torneo y la guarda en `tournaments.image_url`.
  ///
  /// Solo el administrador puede hacerlo (lo imponen RLS y el bucket `media`).
  Future<String> updateTournamentImage({
    required String tournamentId,
    required Uint8List bytes,
    required String extension,
    String? previousUrl,
  }) async {
    final publicUrl = await uploadPublicImage(
      client: _client,
      bucket: 'media',
      folder: 'tournaments/$tournamentId',
      baseName: 'imagen',
      bytes: bytes,
      extension: extension,
    );

    await _client
        .from('tournaments')
        .update({'image_url': publicUrl})
        .eq('id', tournamentId);

    await removePublicImage(
      client: _client,
      bucket: 'media',
      publicUrl: previousUrl,
    );

    return publicUrl;
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
