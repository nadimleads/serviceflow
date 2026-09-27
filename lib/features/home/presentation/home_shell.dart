import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/auth/domain/entities/app_user.dart';
import 'package:serviceflow/features/auth/presentation/logout.dart';
import 'package:serviceflow/features/catalogue/presentation/screens/add_doc_item_screen.dart';
import 'package:serviceflow/features/catalogue/presentation/screens/catalogue_tab.dart';
import 'package:serviceflow/features/clients/presentation/screens/add_client_screen.dart';
import 'package:serviceflow/features/clients/presentation/screens/clients_tab.dart';
import 'package:serviceflow/features/home/presentation/widgets/custom_app_bar.dart';

/// The one signed-in surface, shared by both roles.
///
/// This replaces the old CeoDashboard (which was the whole app) and
/// EmployeeDashboard (which was a stub an Employee could do nothing from).
/// The roles differ by a single flag, so they get a single shell; anything
/// CEO-only is wrapped in `CeoOnly` at the point of use.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'ServiceFlow',
        subtitle: user.email,
        roleLabel: user.role.label,
        onLogout: () => signOutAndReset(context),
      ),

      // IndexedStack, not a swap: switching tabs keeps each tab's scroll
      // position and keeps its Firestore stream attached.
      body: IndexedStack(
        index: _index,
        children: const [ClientsTab(), CatalogueTab()],
      ),

      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClientScreen()),
              ),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add Client'),
            )
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDocItemScreen()),
              ),
              icon: const Icon(Icons.post_add_outlined),
              label: const Text('New Doc Item'),
            ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'All Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Doc List',
          ),
        ],
      ),
    );
  }
}
