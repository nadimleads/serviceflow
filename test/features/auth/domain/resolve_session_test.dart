import 'package:flutter_test/flutter_test.dart';
import 'package:serviceflow/features/auth/domain/entities/app_user.dart';
import 'package:serviceflow/features/auth/domain/entities/auth_user.dart';
import 'package:serviceflow/features/auth/domain/entities/session.dart';
import 'package:serviceflow/features/auth/domain/entities/user_profile.dart';
import 'package:serviceflow/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:serviceflow/features/auth/domain/usecases/resolve_session.dart';

class _FakeProfiles implements UserProfileRepository {
  _FakeProfiles(this._fetch);

  final Future<UserProfile?> Function(String uid) _fetch;

  @override
  Future<UserProfile?> fetchProfile(String uid) => _fetch(uid);
}

void main() {
  const authUser = AuthUser(uid: 'u1', email: 'rina@example.com');

  ResolveSession resolverFor(UserProfile? profile) {
    return ResolveSession(_FakeProfiles((_) async => profile));
  }

  test('resolves a CEO with the stored email and display name', () async {
    final resolve = resolverFor(
      const UserProfile(
        email: 'ceo@office.com',
        displayName: 'Boss',
        rawRole: 'ceo',
      ),
    );

    final result = await resolve(authUser);

    final ready = result as SessionReady;
    expect(ready.user.uid, 'u1');
    expect(ready.user.email, 'ceo@office.com');
    expect(ready.user.displayName, 'Boss');
    expect(ready.user.role, AppRole.ceo);
    expect(ready.user.isCeo, isTrue);
  });

  test('falls back to the auth email and its local part', () async {
    final resolve = resolverFor(const UserProfile(rawRole: 'Employee'));

    final result = await resolve(authUser);

    final ready = result as SessionReady;
    expect(ready.user.email, 'rina@example.com');
    expect(ready.user.displayName, 'rina');
    expect(ready.user.role, AppRole.employee);
    expect(ready.user.isCeo, isFalse);
  });

  test('uses a generic name when there is no email anywhere', () async {
    final resolve = resolverFor(const UserProfile(rawRole: 'ceo'));

    final result = await resolve(const AuthUser(uid: 'u2'));

    final ready = result as SessionReady;
    expect(ready.user.email, '');
    expect(ready.user.displayName, 'User');
  });

  test('reports a missing profile document', () async {
    final result = await resolverFor(null)(authUser);

    final failed = result as SessionFailed;
    expect(failed.problem, SessionProblem.profileMissing);
    expect(failed.detail, 'users/u1');
  });

  test('reports an unrecognised role verbatim', () async {
    final result =
        await resolverFor(const UserProfile(rawRole: 'Manager'))(authUser);

    final failed = result as SessionFailed;
    expect(failed.problem, SessionProblem.unknownRole);
    expect(failed.detail, 'role: "Manager"');
  });

  test('reports a role that was never set', () async {
    final result = await resolverFor(const UserProfile())(authUser);

    final failed = result as SessionFailed;
    expect(failed.problem, SessionProblem.unknownRole);
    expect(failed.detail, 'role: (not set)');
  });

  test('reports a failed read instead of throwing', () async {
    final resolve = ResolveSession(
      _FakeProfiles((_) async => throw StateError('permission-denied')),
    );

    final result = await resolve(authUser);

    final failed = result as SessionFailed;
    expect(failed.problem, SessionProblem.loadFailed);
    expect(failed.detail, contains('permission-denied'));
  });
}
