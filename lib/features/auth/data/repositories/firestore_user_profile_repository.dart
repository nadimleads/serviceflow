import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/features/auth/data/mappers/user_profile_mapper.dart';
import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';
import 'package:serviceflow/features/auth/domain/repositories/user_profile_repository.dart';

/// [UserProfileRepository] backed by the Firestore `users` collection.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._db);

  final FirebaseFirestore _db;

  static const _collection = 'users';

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _db.collection(_collection).doc(uid).get();
    if (!snapshot.exists) return null;
    return UserProfileMapper.fromMap(snapshot.data() ?? const {});
  }
}
