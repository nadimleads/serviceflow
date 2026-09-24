import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Signs out, unwinding the route stack first.
///
/// The pop matters: signing out tears down the [AppUser] provider, and any
/// pushed route still mounted would rebuild without it for one frame. Popping
/// back to the root first means nothing is left reading a session that is
/// about to disappear.
Future<void> signOutAndReset(BuildContext context) async {
  Navigator.of(context).popUntil((route) => route.isFirst);
  await FirebaseAuth.instance.signOut();
}
