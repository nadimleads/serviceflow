import 'package:serviceflow/core/utils/safe_read.dart';
import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';

/// Reads the `users/{uid}` document shape. The only place that knows its
/// field names.
class UserProfileMapper {
  const UserProfileMapper._();

  static UserProfile fromMap(Map<String, dynamic> data) {
    final rawRole = data['role'];
    return UserProfile(
      email: _stringOrNull(data['email']),
      displayName: _stringOrNull(data['displayName']),
      // Kept as text whatever was typed, so the error screen can quote it.
      rawRole: rawRole == null ? null : asString(rawRole),
    );
  }

  static String? _stringOrNull(Object? value) {
    return value is String ? value : null;
  }
}
