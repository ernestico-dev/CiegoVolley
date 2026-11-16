/// Torneo.
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.status,
    this.venue,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final String name;
  final String status;
  final String? venue;
  final DateTime? startsOn;
  final DateTime? endsOn;

  bool get isFinished => status == 'finished';

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Sin nombre',
      status: map['status'] as String? ?? 'draft',
      venue: map['venue'] as String?,
      startsOn: DateTime.tryParse(map['starts_on'] as String? ?? ''),
      endsOn: DateTime.tryParse(map['ends_on'] as String? ?? ''),
    );
  }
}
