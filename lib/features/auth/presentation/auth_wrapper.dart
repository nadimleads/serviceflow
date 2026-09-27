import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/auth/domain/entities/app_user.dart';
import 'package:serviceflow/features/auth/presentation/screens/welcome_screen.dart';
import 'package:serviceflow/features/home/presentation/home_shell.dart';

/// Picks the root route for the current session.
///
/// `AuthScope` mounts a `Provider<AppUser>` above the Navigator only once a
/// signed-in user's role has been resolved, and remounts the Navigator on
/// every auth transition. So this widget is always built fresh with a settled
/// state, and "is there an AppUser above me" is exactly "am I signed in".
/// No second auth stream, and nothing here touches Firebase.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>();
    return user == null ? const WelcomeScreen() : const HomeShell();
  }
}
