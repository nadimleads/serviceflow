import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';
import 'package:serviceflow/features/auth/domain/repositories/auth_repository.dart';

/// The app's one auth subscription. Only `AuthScope` should call this.
class WatchAuthState {
  const WatchAuthState(this._auth);

  final AuthRepository _auth;

  Stream<AuthUser?> call() => _auth.authStateChanges();
}
