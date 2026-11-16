/// Datos mínimos de un usuario registrado.
class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'member',
    this.avatarUrl,
    this.notificationsEnabled = false,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final bool notificationsEnabled;

  bool get isAdmin => role == 'admin';

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  /// Iniciales para cuando el usuario todavía no tiene avatar.
  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final letters = parts.map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  factory ProfileSummary.fromMap(Map<String, dynamic> map) {
    return ProfileSummary(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      avatarUrl: map['avatar_url'] as String?,
      notificationsEnabled: map['notifications_enabled'] as bool? ?? false,
    );
  }
}
