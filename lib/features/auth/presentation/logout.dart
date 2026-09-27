import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/auth/domain/usecases/sign_out.dart';

/// Signs out, unwinding the route stack first.
///
/// The pop matters: signing out tears down the `AppUser` provider, and any
/// pushed route still mounted would rebuild without it for one frame. Popping
/// back to the root first means nothing is left reading a session that is
/// about to disappear.
Future<void> signOutAndReset(BuildContext context) async {
  final signOut = context.read<SignOut>();
  Navigator.of(context).popUntil((route) => route.isFirst);
  await signOut();
}
