import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/models/app_user.dart';

/// Renders [child] only for the CEO.
///
/// This is UX, not enforcement — hiding a button stops a mistake, it does not
/// stop a request. `firestore.rules` is what actually enforces the split.
///
/// There are exactly six call sites in the finished app:
///   1. Doc List — edit name/price
///   2. Doc List — retire / relist
///   3. Doc List — delete permanently
///   4. Client profile — Basic Information edit
///   5. Client profile — File Information edit
///   6. Client profile — active switch and delete client
///
/// If you find yourself adding a seventh, the spec changed.
class CeoOnly extends StatelessWidget {
  const CeoOnly({super.key, required this.child, this.fallback});

  final Widget child;

  /// Shown to an Employee instead. Defaults to nothing at all.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final isCeo = context.select<AppUser, bool>((user) => user.isCeo);
    return isCeo ? child : (fallback ?? const SizedBox.shrink());
  }
}
