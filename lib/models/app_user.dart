/// The signed-in user, resolved once at login from Firebase Auth + `users/{uid}`.
///
/// This is the single source of truth for "who am I and what may I do".
/// Nothing below [AuthScope] should read `FirebaseAuth.instance.currentUser`.
library;

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

  /// Builds a user from the auth record plus the `users/{uid}` document data.
  ///
  /// Returns null when the role is missing or unrecognised — the caller turns
  /// that into a named error screen rather than guessing at permissions.
  static AppUser? from({
    required String uid,
    required String? authEmail,
    required Map<String, dynamic>? profile,
  }) {
    final role = AppRole.tryParse(profile?['role']);
    if (role == null) return null;

    final email = (profile?['email'] as String?)?.trim().isNotEmpty == true
        ? (profile!['email'] as String).trim()
        : (authEmail ?? '');

    final stored = (profile?['displayName'] as String?)?.trim();
    final displayName = (stored != null && stored.isNotEmpty)
        ? stored
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
