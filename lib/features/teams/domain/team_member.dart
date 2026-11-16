/// Integrante de un equipo (usuario registrado en la plataforma).
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final DateTime? joinedAt;

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  /// Iniciales para cuando el jugador no tiene avatar.
  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final letters = parts.map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profile'] as Map<String, dynamic>? ?? const {};

    return TeamMember(
      userId: profile['id'] as String? ?? '',
      fullName: profile['full_name'] as String? ?? '',
      email: profile['email'] as String? ?? '',
      role: map['role'] as String? ?? 'player',
      avatarUrl: profile['avatar_url'] as String?,
      joinedAt: DateTime.tryParse(map['joined_at'] as String? ?? ''),
    );
  }
}
