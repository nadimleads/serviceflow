import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviceflow/ceo/custome_appbar.dart';
import 'package:serviceflow/client/clients_profile.dart';
import 'package:serviceflow/doc/add_new_doc.dart';

class CeoDashboard extends StatelessWidget {
  const CeoDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final loggedUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      extendBody: true,

      appBar: CustomAppBar(title: "ServiceFlow", subtitle: loggedUser.email!),

      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('clients')
                .where('active', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Active Clients available right now'),
            );
          }

          final clients = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Clients',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                /// 🟡 Yellow container like your design
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 218, 245, 255),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final doc = clients[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final clientsName =
                            data['clientsname'] ?? 'Unknown Client';
                        final fileStatus =
                            data['fileStatus'] ?? 'Unknown Status';
                        final fileType = data['fileType'] ?? 'Unknown Type';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ClientsProfile(
                                        clientsId: doc.id,
                                        clientsName: clientsName,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 240, 255, 200),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$clientsName • ($fileType)',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "$fileStatus ",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                              255,
                                              44,
                                              44,
                                              44,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 30,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      /// Bottom Navigation
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 9, 0, 108),
            currentIndex: 0,
            elevation: 0,
            selectedItemColor: const Color.fromARGB(255, 255, 244, 185),
            unselectedItemColor: const Color.fromRGBO(255, 249, 212, 1),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Logout',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_add_alt_rounded),
                label: 'Add Client',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.post_add_outlined),
                label: 'Add Documnet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Document List',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  _logout(context);
                  break;
                case 1:
                  // Navigate later
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddNewDoc()),
                  );
                  break;
                case 3:
                  // Navigate later
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}
