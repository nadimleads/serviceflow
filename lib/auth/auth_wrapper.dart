import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/app/home_shell.dart';
import 'package:serviceflow/welcomscr.dart';

/// Picks the root route for the current auth state.
///
/// A synchronous read is safe here, and the role lookup that used to live in
/// this file is gone. [AuthScope] owns the auth stream, resolves the role
/// before mounting the Navigator, and remounts the Navigator on every auth
/// transition — so this widget is always built fresh with a settled state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser == null
        ? const Welcomescreen()
        : const HomeShell();
  }
}
