/// Datos mínimos de un usuario registrado.
class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  factory ProfileSummary.fromMap(Map<String, dynamic> map) {
    return ProfileSummary(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }
}
