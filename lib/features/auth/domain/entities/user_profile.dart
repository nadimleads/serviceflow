/// The `users/{uid}` record as stored, before any interpretation.
///
/// Every field is optional because the document is typed by hand in the
/// Firebase console. Deciding what a missing or odd value means is the job of
/// `AppUser.from` and `ResolveSession`, not of the data layer.
class UserProfile {
  const UserProfile({this.email, this.displayName, this.rawRole});

  final String? email;
  final String? displayName;

  /// The stored role, untouched, so an unrecognised value can be shown
  /// verbatim on the error screen.
  final String? rawRole;
}
