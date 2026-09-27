import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/app/app.dart';
import 'package:serviceflow/app/injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ServiceFlowApp(providers: buildFirebaseProviders()));
}
