import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';

/// The hand-maintained `users/{uid}` profiles.
///
/// Read-only on purpose: the app never writes here. The CEO creates every
/// account, and its role, in the Firebase console.
abstract interface class UserProfileRepository {
  /// The stored profile, or null when no document exists for [uid].
  Future<UserProfile?> fetchProfile(String uid);
}
