enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  static UserRole roleFromString(String? value) =>
      value == 'admin' ? UserRole.admin : UserRole.student;
}
