import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:serviceflow/features/auth/presentation/auth_scope.dart';
import 'package:serviceflow/features/auth/presentation/auth_wrapper.dart';

/// The root widget: use-case providers, then MaterialApp, then the session.
class ServiceFlowApp extends StatelessWidget {
  const ServiceFlowApp({super.key, required this.providers});

  /// The use-case providers built by `injection.dart`.
  ///
  /// They sit ABOVE MaterialApp so they are visible both to [AuthScope], which
  /// renders above the Navigator, and to every route the Navigator ever pushes.
  final List<SingleChildWidget> providers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ServiceFlow App',

        // ─────────────────────────────────────────────────────────────────
        //  AuthScope belongs HERE and nowhere else.
        //
        //  `builder`'s `child` is the Navigator itself, so the session
        //  provider mounted inside AuthScope is visible to every route,
        //  including ones pushed later. Move this into `home:`, AuthWrapper,
        //  or HomeShell and every pushed route loses the provider — a runtime
        //  ProviderNotFoundException, not a compile error, and it will not
        //  show up until someone opens a client profile.
        // ─────────────────────────────────────────────────────────────────
        builder: (context, child) => AuthScope(child: child!),

        home: const AuthWrapper(),
      ),
    );
  }
}
