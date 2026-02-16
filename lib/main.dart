import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:serviceflow/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/provider/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServiceFlow',
      home: const AuthWrapper(),
    );
  }
}
