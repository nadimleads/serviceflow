import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/provider/auth_provider.dart';

class CeoDashboard extends StatelessWidget {
  const CeoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CEO Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
      ),
      body: const Center(child: Text('CEO Dashboard')),
    );
  }
}
