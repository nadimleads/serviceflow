import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/ceo/ceo_dashboard.dart';
import 'package:serviceflow/employee/employee_dashboard.dart';
import 'package:serviceflow/welcomscr.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 Waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!snapshot.hasData) {
          return const Welcomescreen();
        }

        // ✅ Logged in → fetch role
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("No role assigned.")),
              );
            }

            final role = roleSnapshot.data!.get('role');

            if (role == "CEO") {
              return CeoDashboard();
            }

            if (role == "Senior Manager") {
              return CeoDashboard();
            }

            if (role == "Employee") {
              return EmployeeDashboard();
            }
            //IMPORTANT FALLBACK For Null safety
            return Scaffold(
              body: Center(
                child: Text(
                  "Unknown or unsupported role.\nPlease contact support.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
