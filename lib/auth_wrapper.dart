import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/employee/employee_dashboard.dart';
import 'package:serviceflow/provider/auth_provider.dart';
import 'package:serviceflow/ceo/ceo_dashboard.dart';
import 'package:serviceflow/loading.dart';
import 'package:serviceflow/useroption.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const LoadingScreen();
    }

    if (!auth.isAuthenticated) {
      return const Useroption();
    }

    // Role check
    if (auth.role == 'ceo') {
      return const CeoDashboard();
    }

    if (auth.role == 'teammate') {
      return const TeammateDashboard();
    }

    // Optional fallback if role mismatch
    return const Scaffold(body: Center(child: Text("Access Denied")));
  }
}
