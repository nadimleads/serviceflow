import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DocListScreen extends StatelessWidget {
  const DocListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Documents List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('docItems').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Documents!", style: TextStyle(fontSize: 16)),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, ndxctx) {
              final docItem = documents[ndxctx];
              final name = (docItem['name'] ?? '').toString();
              final price = docItem['price'];
              final isAvailable = docItem.get('isAvailable') as bool? ?? true;

              //for firestore error defense
              if (name.isEmpty || price == null || price <= 0) {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isAvailable ? Colors.white : Colors.grey.shade200,
                child: ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black : Colors.grey,
                      decoration:
                          isAvailable ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    "৳ $price",
                    style: TextStyle(
                      color: isAvailable ? Colors.black54 : Colors.grey,
                    ),
                  ),
                  leading: Switch(
                    value: isAvailable,
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('docItems')
                          .doc(docItem.id)
                          .update({'isAvailable': value});
                    },
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context, docItem);
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(value: 'edit', child: Text("Edit")),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, QueryDocumentSnapshot doc) {
    final nameController = TextEditingController(text: doc['name']);

    final priceController = TextEditingController(
      text: doc['price'].toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Document Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Document Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();

                if (name.isEmpty || priceText.isEmpty) {
                  return;
                }

                final price = int.tryParse(priceText);
                if (price == null || price <= 0) {
                  return;
                }

                // Close dialog immediately
                Navigator.pop(dialogContext);

                // Background update
                await FirebaseFirestore.instance
                    .collection('docItems')
                    .doc(doc.id)
                    .update({'name': name, 'price': price});
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      priceController.dispose();
    });
  }
}
