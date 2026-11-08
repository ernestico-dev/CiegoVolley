/// Equipo de voleibol.
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.category,
    this.season,
  });

  final String id;
  final String name;
  final String category;
  final String? season;

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Sin nombre',
      category: map['category'] as String? ?? 'senior',
      season: map['season'] as String?,
    );
  }
}
