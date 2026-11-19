import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/email_validator.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/failures.dart';
import 'core_providers.dart';

/// Signed-in uid or null. Firebase persists the session, so after an app
/// restart this emits the previous uid without asking for a login.
final authStateProvider = StreamProvider<String?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Live users/{uid} document (name + role). Watching it means flipping the
/// role to 'admin' in the console makes the Admin tab appear immediately.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(uid);
});

/// Login / sign-up / logout action. The UI shows errors via ref.listen.
class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signIn(String email, String password) => _run(() async {
        _checkDomain(email);
        await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
      });

  Future<void> signUp(String name, String email, String password) =>
      _run(() async {
        if (name.trim().isEmpty) throw const AuthFailure('Name is required.');
        // Client-side domain check BEFORE calling Firebase.
        _checkDomain(email);
        await ref
            .read(authRepositoryProvider)
            .signUp(name: name, email: email, password: password);
      });

  Future<void> signOut() => _run(() => ref.read(authRepositoryProvider).signOut());

  void _checkDomain(String email) {
    if (!EmailDomainValidator.isAllowed(email)) {
      throw const AuthFailure(
          'Only @${EmailDomainValidator.allowedDomain} emails are allowed.');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
