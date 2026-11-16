import 'tournament.dart';

/// Inscripción de un equipo en un torneo.
class TeamTournament {
  const TeamTournament({
    required this.tournament,
    required this.status,
    this.registeredAt,
  });

  final Tournament tournament;
  final String status;
  final DateTime? registeredAt;

  factory TeamTournament.fromMap(Map<String, dynamic> map) {
    final raw = map['tournament'] as Map<String, dynamic>? ?? const {};

    return TeamTournament(
      tournament: Tournament.fromMap(raw),
      status: map['status'] as String? ?? 'registered',
      registeredAt: DateTime.tryParse(map['registered_at'] as String? ?? ''),
    );
  }
}
