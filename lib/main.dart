import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:serviceflow/app/auth_scope.dart';
import 'package:serviceflow/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ServiceFlowApp());
}

class ServiceFlowApp extends StatelessWidget {
  const ServiceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServiceFlow App',

      // ───────────────────────────────────────────────────────────────────
      //  AuthScope belongs HERE and nowhere else.
      //
      //  `builder`'s `child` is the Navigator itself, so the session provider
      //  mounted inside AuthScope is visible to every route, including ones
      //  pushed later. Move this into `home:`, AuthWrapper, or HomeShell and
      //  every pushed route loses the provider — a runtime
      //  ProviderNotFoundException, not a compile error, and it will not show
      //  up until someone opens a client profile.
      // ───────────────────────────────────────────────────────────────────
      builder: (context, child) => AuthScope(child: child!),

      home: const AuthWrapper(),
    );
  }
}
