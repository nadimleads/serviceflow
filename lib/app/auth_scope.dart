import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/app/session_error_screen.dart';
import 'package:serviceflow/loading.dart';
import 'package:serviceflow/models/app_user.dart';

/// Owns the app's only auth stream and puts [AppUser] above the Navigator.
///
/// ─────────────────────────────────────────────────────────────────────────
///  THIS MUST BE INSTALLED VIA `MaterialApp.builder`, NOT `home:`.
///
///  `home:` is a *route*. Providers mounted inside a route are invisible to
///  anything pushed on top of it, so `context.read<AppUser>()` inside a client
///  profile would throw ProviderNotFoundException — at runtime, not compile
///  time. `builder`'s `child` argument IS the Navigator, so providers placed
///  here are visible to every route.
/// ─────────────────────────────────────────────────────────────────────────
///
/// Signing in or out changes the shape of this subtree, which remounts the
/// Navigator and discards the route stack. That is deliberate: a signed-out
/// user must not be left looking at a client profile, and the freshly mounted
/// [AuthWrapper] can read `currentUser` synchronously without racing.
class AuthScope extends StatelessWidget {
  const AuthScope({super.key, required this.child});

  /// The Navigator handed over by `MaterialApp.builder`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          // Signed out — the Navigator shows the welcome/login path, which
          // needs no providers.
          return child;
        }

        return _SessionLoader(
          key: ValueKey(user.uid),
          authUser: user,
          child: child,
        );
      },
    );
  }
}

/// Fetches `users/{uid}` exactly once per sign-in.
///
/// Stateful on purpose. The previous implementation kicked off the read inside
/// `FutureBuilder(future: ...get())` in `build()`, which re-issues the request
/// on every single rebuild.
class _SessionLoader extends StatefulWidget {
  const _SessionLoader({
    super.key,
    required this.authUser,
    required this.child,
  });

  final User authUser;
  final Widget child;

  @override
  State<_SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<_SessionLoader> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _fetch();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetch() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.authUser.uid)
        .get()
        .timeout(const Duration(seconds: 15));
  }

  void _retry() => setState(() => _profile = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return SessionErrorScreen(
            problem: SessionProblem.loadFailed,
            detail: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return SessionErrorScreen(
            problem: SessionProblem.profileMissing,
            detail: 'users/${widget.authUser.uid}',
            onRetry: _retry,
          );
        }

        final user = AppUser.from(
          uid: widget.authUser.uid,
          authEmail: widget.authUser.email,
          profile: doc.data(),
        );

        if (user == null) {
          final raw = doc.data()?['role'];
          return SessionErrorScreen(
            problem: SessionProblem.unknownRole,
            detail: raw == null ? 'role: (not set)' : 'role: "$raw"',
            onRetry: _retry,
          );
        }

        return MultiProvider(
          providers: [Provider<AppUser>.value(value: user)],
          child: widget.child,
        );
      },
    );
  }
}
