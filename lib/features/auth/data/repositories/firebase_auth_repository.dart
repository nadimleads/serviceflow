import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';
import 'package:serviceflow/features/auth/domain/exceptions/sign_in_exception.dart';
import 'package:serviceflow/features/auth/domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toAuthUser);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw SignInException(_errorFor(e.code), message: e.message);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }

  /// Firebase error codes → provider-neutral reasons. Unknown codes keep
  /// Firebase's own message so the UI can still show something specific.
  static SignInError _errorFor(String code) {
    return switch (code) {
      'invalid-email' => SignInError.invalidEmail,
      'user-disabled' => SignInError.userDisabled,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => SignInError.wrongCredentials,
      'network-request-failed' => SignInError.network,
      'too-many-requests' => SignInError.tooManyRequests,
      _ => SignInError.unknown,
    };
  }
}
