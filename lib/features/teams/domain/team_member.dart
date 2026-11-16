/// Integrante de un equipo (usuario registrado en la plataforma).
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? joinedAt;

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profile'] as Map<String, dynamic>? ?? const {};

    return TeamMember(
      userId: profile['id'] as String? ?? '',
      fullName: profile['full_name'] as String? ?? '',
      email: profile['email'] as String? ?? '',
      role: map['role'] as String? ?? 'player',
      joinedAt: DateTime.tryParse(map['joined_at'] as String? ?? ''),
    );
  }
}
