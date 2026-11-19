import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in uid, or null. Firebase restores the session on
  /// app restart, so this emits the persisted uid on cold start.
  Stream<String?> authStateChanges();

  /// Live `users/{uid}` profile (role changes show up immediately).
  Stream<AppUser?> watchUser(String uid);

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
