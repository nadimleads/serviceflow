import 'package:serviceflow/features/auth/domain/entities/app_user.dart';
import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';
import 'package:serviceflow/features/auth/domain/entities/session.dart';
import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';
import 'package:serviceflow/features/auth/domain/repositories/user_profile_repository.dart';

/// Turns an auth identity into an [AppUser] by fetching its stored profile.
///
/// Runs exactly once per sign-in (the caller caches the result) and never
/// throws: every failure comes back as a [SessionFailed] naming the problem,
/// so the UI can show a specific, escapable error instead of a dead end.
class ResolveSession {
  const ResolveSession(this._profiles);

  final UserProfileRepository _profiles;

  /// How long the one profile read may take before it counts as a failure.
  static const timeout = Duration(seconds: 15);

  Future<SessionResult> call(AuthUser authUser) async {
    final UserProfile? profile;
    try {
      profile = await _profiles.fetchProfile(authUser.uid).timeout(timeout);
    } catch (e) {
      return SessionFailed(SessionProblem.loadFailed, detail: e.toString());
    }

    if (profile == null) {
      return SessionFailed(
        SessionProblem.profileMissing,
        detail: 'users/${authUser.uid}',
      );
    }

    final user = AppUser.from(
      uid: authUser.uid,
      authEmail: authUser.email,
      profile: profile,
    );
    if (user == null) {
      final raw = profile.rawRole;
      return SessionFailed(
        SessionProblem.unknownRole,
        detail: raw == null ? 'role: (not set)' : 'role: "$raw"',
      );
    }

    return SessionReady(user);
  }
}
