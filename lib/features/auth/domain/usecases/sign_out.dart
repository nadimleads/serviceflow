import 'package:serviceflow/features/auth/domain/repositories/auth_repository.dart';

/// Signs out. The auth stream then rebuilds the app in its signed-out shape.
class SignOut {
  const SignOut(this._auth);

  final AuthRepository _auth;

  Future<void> call() => _auth.signOut();
}
