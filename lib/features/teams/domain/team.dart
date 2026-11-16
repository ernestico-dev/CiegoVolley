/// Equipo de voleibol.
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerId,
    this.season,
    this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final String ownerId;
  final String? season;
  final DateTime? createdAt;

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Sin nombre',
      category: map['category'] as String? ?? 'Senior',
      ownerId: map['owner_id'] as String? ?? '',
      season: map['season'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    );
  }
}
