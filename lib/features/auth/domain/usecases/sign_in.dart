import 'package:serviceflow/features/auth/domain/repositories/auth_repository.dart';

/// Signs in with email and password.
///
/// Nothing to return: a successful sign-in flips the auth stream, and the
/// session layer rebuilds the app from the top.
class SignIn {
  const SignIn(this._auth);

  final AuthRepository _auth;

  Future<void> call({required String email, required String password}) {
    return _auth.signIn(email: email.trim(), password: password);
  }
}
