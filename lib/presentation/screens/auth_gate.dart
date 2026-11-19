import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Routes on auth state. Because Firebase Auth persists the session, a
/// restarted app goes straight to HomeShell.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
      data: (uid) => uid == null ? const LoginScreen() : const HomeShell(),
    );
  }
}
