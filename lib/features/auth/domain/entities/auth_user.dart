/// The bare signed-in identity from the auth provider, before the profile
/// lookup that turns it into an `AppUser`.
class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}
