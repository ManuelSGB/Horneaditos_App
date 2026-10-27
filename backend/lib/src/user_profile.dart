class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String status;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id']! as String,
      firstName: map['nombre']! as String,
      lastName: map['apellido']! as String,
      email: map['correo']! as String,
      role: map['rol']! as String,
      status: map['estado']! as String,
    );
  }
}
