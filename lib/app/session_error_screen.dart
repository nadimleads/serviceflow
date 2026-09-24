import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Why the session could not be established.
enum SessionProblem {
  /// The `users/{uid}` read threw — offline, or rules denied it.
  loadFailed,

  /// Signed in, but no `users/{uid}` document exists.
  profileMissing,

  /// The document exists but `role` is absent or not one we recognise.
  unknownRole,
}

/// Shown when a signed-in user cannot be resolved to a role.
///
/// This renders ABOVE the Navigator, so it must never call `Navigator.of`,
/// `showDialog`, or `ScaffoldMessenger.of`. Both actions are self-contained.
///
/// It replaces the old bare "No role assigned." text, which collapsed three
/// very different failures into one dead end with no way out.
class SessionErrorScreen extends StatelessWidget {
  const SessionErrorScreen({
    super.key,
    required this.problem,
    required this.onRetry,
    this.detail,
  });

  final SessionProblem problem;
  final VoidCallback onRetry;

  /// The offending value or error text, shown verbatim so the fix is obvious.
  final String? detail;

  String get _title => switch (problem) {
        SessionProblem.loadFailed => "Couldn't load your account",
        SessionProblem.profileMissing => 'Account not set up',
        SessionProblem.unknownRole => 'Unrecognised role',
      };

  String get _body => switch (problem) {
        SessionProblem.loadFailed =>
          'We signed you in, but reading your profile failed. This is usually '
              'a connection problem.',
        SessionProblem.profileMissing =>
          'You are signed in, but there is no profile record for this account. '
              'Ask the CEO to add a users document with your role.',
        SessionProblem.unknownRole =>
          'Your profile has a role we do not recognise. It must be either '
              'CEO or Employee.',
      };

  IconData get _icon => switch (problem) {
        SessionProblem.loadFailed => Icons.cloud_off_rounded,
        SessionProblem.profileMissing => Icons.person_off_outlined,
        SessionProblem.unknownRole => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(_icon, size: 56, color: const Color(0xFF64748B)),
                  const SizedBox(height: 20),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  if (detail != null && detail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        detail!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    // Safe here: signing out flips the auth stream, which
                    // rebuilds everything from the top. No Navigator needed.
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
