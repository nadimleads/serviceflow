/// Demo sign-in details shown on the login screen.
///
/// ServiceFlow has no sign-up flow by design — the CEO creates every account
/// by hand in the Firebase console. That makes the app impossible to try
/// without being handed credentials, which is awkward when the point is to
/// demonstrate it. So the two demo accounts are printed on the login screen
/// and can be filled in with a tap.
///
/// ─────────────────────────────────────────────────────────────────────────
///  These accounts must exist for the buttons to work. For each one:
///    1. Firebase console → Authentication → Users → Add user
///       (use the email and password below, exactly)
///    2. Firestore → users → add a document whose ID is that user's UID:
///         role        : "ceo"   or  "employee"
///         displayName : "Demo CEO"  or  "Demo Employee"
///         email       : the same email
///
///  Before shipping this to anyone real: delete this file, remove the demo
///  card from login.dart, and rotate these passwords. Printed credentials are
///  fine for a showcase and nowhere else.
/// ─────────────────────────────────────────────────────────────────────────
library;

class DemoAccount {
  const DemoAccount({
    required this.roleLabel,
    required this.email,
    required this.password,
    required this.blurb,
  });

  final String roleLabel;
  final String email;
  final String password;

  /// One line on what this role can do, so the difference is visible.
  final String blurb;
}

const List<DemoAccount> kDemoAccounts = [
  DemoAccount(
    roleLabel: 'CEO',
    email: 'ceo@serviceflow.app',
    password: 'Ceo@12345',
    blurb: 'Full access — can also edit & delete',
  ),
  DemoAccount(
    roleLabel: 'Employee',
    email: 'employee@serviceflow.app',
    password: 'Emp@12345',
    blurb: 'Everything except editing & deleting',
  ),
];
