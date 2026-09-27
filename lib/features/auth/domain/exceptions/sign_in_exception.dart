/// Why a sign-in attempt was rejected, independent of the auth provider.
enum SignInError {
  invalidEmail,
  userDisabled,
  wrongCredentials,
  network,
  tooManyRequests,
  unknown,
}

/// Thrown by `AuthRepository.signIn`.
///
/// The data layer translates the provider's own error codes into a
/// [SignInError], so the login screen never has to know a Firebase type.
class SignInException implements Exception {
  const SignInException(this.error, {this.message});

  final SignInError error;

  /// The provider's own message, if any, for the [SignInError.unknown] case.
  final String? message;

  @override
  String toString() {
    return message == null
        ? 'SignInException($error)'
        : 'SignInException($error): $message';
  }
}
