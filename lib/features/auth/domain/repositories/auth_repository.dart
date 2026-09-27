import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';

/// Identity: who is signed in, and signing in or out.
///
/// Implementations translate provider-specific errors into a
/// `SignInException`, so nothing above this interface depends on Firebase.
abstract interface class AuthRepository {
  /// Emits the current identity immediately on listen, then on every change.
  Stream<AuthUser?> authStateChanges();

  /// Throws a `SignInException` when the credentials are rejected.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}
