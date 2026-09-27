import 'package:flutter/material.dart';

/// Full-screen placeholder while the auth stream or the session resolves.
///
/// This can render ABOVE the Navigator (from `MaterialApp.builder`), so it
/// must never call `Navigator.of`, `showDialog` or `ScaffoldMessenger.of`.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceFlow')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Loading....',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
