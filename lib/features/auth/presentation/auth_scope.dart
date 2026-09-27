import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/core/widgets/loading_screen.dart';
import 'package:serviceflow/features/auth/domain/entities/app_user.dart';
import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';
import 'package:serviceflow/features/auth/domain/entities/session.dart';
import 'package:serviceflow/features/auth/domain/usecases/resolve_session.dart';
import 'package:serviceflow/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:serviceflow/features/auth/presentation/screens/session_error_screen.dart';

/// Owns the app's only auth subscription and puts [AppUser] above the Navigator.
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
/// `AuthWrapper` can read the session synchronously without racing.
class AuthScope extends StatefulWidget {
  const AuthScope({super.key, required this.child});

  /// The Navigator handed over by `MaterialApp.builder`.
  final Widget child;

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> {
  // Subscribed once. Re-creating the stream on every rebuild would re-emit
  // the current state, bounce through LoadingScreen and remount the Navigator.
  late final Stream<AuthUser?> _authState;

  @override
  void initState() {
    super.initState();
    final watchAuthState = context.read<WatchAuthState>();
    _authState = watchAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final authUser = snapshot.data;
        if (authUser == null) {
          // Signed out — the Navigator shows the welcome/login path, which
          // needs no session.
          return widget.child;
        }

        return _SessionLoader(
          key: ValueKey(authUser.uid),
          authUser: authUser,
          child: widget.child,
        );
      },
    );
  }
}

/// Resolves the session exactly once per sign-in.
///
/// Stateful on purpose: the profile read is issued in `initState`, never in
/// `build`, so a rebuild cannot re-issue the request.
class _SessionLoader extends StatefulWidget {
  const _SessionLoader({
    super.key,
    required this.authUser,
    required this.child,
  });

  final AuthUser authUser;
  final Widget child;

  @override
  State<_SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<_SessionLoader> {
  late Future<SessionResult> _session;

  @override
  void initState() {
    super.initState();
    _session = _resolve();
  }

  Future<SessionResult> _resolve() {
    final resolveSession = context.read<ResolveSession>();
    return resolveSession(widget.authUser);
  }

  void _retry() => setState(() => _session = _resolve());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionResult>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final result = snapshot.data;
        if (result == null) {
          // ResolveSession never throws, so this is a programming error rather
          // than a network one. Still name it rather than hang on a spinner.
          return SessionErrorScreen(
            problem: SessionProblem.loadFailed,
            detail: snapshot.error?.toString(),
            onRetry: _retry,
          );
        }

        return switch (result) {
          SessionReady(:final user) => Provider<AppUser>.value(
              value: user,
              child: widget.child,
            ),
          SessionFailed(:final problem, :final detail) => SessionErrorScreen(
              problem: problem,
              detail: detail,
              onRetry: _retry,
            ),
        };
      },
    );
  }
}
