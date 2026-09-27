import 'package:serviceflow/features/auth/domain/entities/app_user.dart';

/// Why a signed-in user could not be resolved to an [AppUser].
enum SessionProblem {
  /// The profile read threw — offline, timed out, or rules denied it.
  loadFailed,

  /// Signed in, but no `users/{uid}` document exists.
  profileMissing,

  /// The document exists but `role` is absent or not one we recognise.
  unknownRole,
}

/// The outcome of resolving a session: exactly one of the two cases below.
sealed class SessionResult {
  const SessionResult();
}

class SessionReady extends SessionResult {
  const SessionReady(this.user);

  final AppUser user;
}

class SessionFailed extends SessionResult {
  const SessionFailed(this.problem, {this.detail});

  final SessionProblem problem;

  /// The offending value or error text, shown verbatim so the fix is obvious.
  final String? detail;
}
