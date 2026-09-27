/// The signed-in user, resolved once at login from the auth identity plus the
/// stored `users/{uid}` profile.
///
/// This is the single source of truth for "who am I and what may I do".
/// Nothing below `AuthScope` should ask the auth provider directly.
library;

import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';

enum AppRole {
  ceo('ceo', 'CEO'),
  employee('employee', 'Employee');

  const AppRole(this.wire, this.label);

  /// The value stored in `users/{uid}.role`.
  final String wire;

  /// What the user sees.
  final String label;

  /// Parses a stored role, tolerating whitespace and casing.
  ///
  /// Accepts the current database spellings ('CEO', 'Employee') as well as the
  /// lowercase wire values, so this stage ships without touching `users/`.
  static AppRole? tryParse(Object? raw) {
    if (raw is! String) return null;

    switch (raw.trim().toLowerCase()) {
      case 'ceo':
        return AppRole.ceo;
      case 'employee':
        return AppRole.employee;

      // TEMPORARY BRIDGE — remove when `users/` is re-typed by hand.
      // 'Senior Manager' is not a role in the spec, but it exists in the
      // database today and routes to the full CEO surface. Aliasing it here
      // keeps that account working; dropping it would lock them out with no
      // warning. See docs/BUILD_PLAN.md, owner question 1.
      case 'senior manager':
        return AppRole.ceo;

      default:
        return null;
    }
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final AppRole role;

  /// The one permission difference in the whole app: the CEO alone may edit or
  /// delete doc items and clients. Everything else is open to both roles.
  bool get isCeo => role == AppRole.ceo;

  /// Builds a user from the auth identity plus the stored profile.
  ///
  /// Returns null when the profile's role is missing or unrecognised — the
  /// caller turns that into a named error rather than guessing at permissions.
  static AppUser? from({
    required String uid,
    required String? authEmail,
    required UserProfile profile,
  }) {
    final role = AppRole.tryParse(profile.rawRole);
    if (role == null) return null;

    final storedEmail = profile.email?.trim();
    final email = (storedEmail != null && storedEmail.isNotEmpty)
        ? storedEmail
        : (authEmail ?? '');

    final storedName = profile.displayName?.trim();
    final displayName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : _localPart(email);

    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
    );
  }

  static String _localPart(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return email.isEmpty ? 'User' : email;
    return email.substring(0, at);
  }
}
