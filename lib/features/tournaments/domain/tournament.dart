/// Fases de un torneo.
enum TournamentStage {
  league('league', 'Liga'),
  quarterfinal('quarterfinal', 'Cuartos'),
  semifinal('semifinal', 'Semifinales'),
  finalStage('final', 'Final');

  const TournamentStage(this.dbValue, this.label);

  final String dbValue;
  final String label;

  bool get isKnockout => this != TournamentStage.league;

  static TournamentStage fromDb(String? value) {
    for (final stage in TournamentStage.values) {
      if (stage.dbValue == value) return stage;
    }
    return TournamentStage.league;
  }

  /// Orden de las rondas eliminatorias (la liga no entra).
  static const knockout = [
    TournamentStage.quarterfinal,
    TournamentStage.semifinal,
    TournamentStage.finalStage,
  ];

  TournamentStage? get next {
    return switch (this) {
      TournamentStage.league => TournamentStage.quarterfinal,
      TournamentStage.quarterfinal => TournamentStage.semifinal,
      TournamentStage.semifinal => TournamentStage.finalStage,
      TournamentStage.finalStage => null,
    };
  }
}

/// Torneo.
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.status,
    this.stage = TournamentStage.league,
    this.venue,
    this.imageUrl,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final String name;
  final String status;
  final TournamentStage stage;
  final String? venue;
  final String? imageUrl;
  final DateTime? startsOn;
  final DateTime? endsOn;

  bool get isFinished => status == 'finished';

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Sin nombre',
      status: map['status'] as String? ?? 'draft',
      stage: TournamentStage.fromDb(map['stage'] as String?),
      venue: map['venue'] as String?,
      imageUrl: map['image_url'] as String?,
      startsOn: DateTime.tryParse(map['starts_on'] as String? ?? ''),
      endsOn: DateTime.tryParse(map['ends_on'] as String? ?? ''),
    );
  }
}
