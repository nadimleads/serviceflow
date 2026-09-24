import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/widgets/ceo_only.dart';

/// The catalogue body — the "menu" of documents and their prices.
///
/// Body only, no Scaffold: it is hosted by the Doc List tab in the shell.
///
/// Both roles may CREATE items (the shell's FAB). Only the CEO may edit,
/// retire or relist one, so every mutating affordance lives inside the
/// [CeoOnly] popup menu. An Employee sees the list and nothing else.
class DocListView extends StatelessWidget {
  const DocListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('docItems').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No documents yet', style: TextStyle(fontSize: 16)),
          );
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final docItem = documents[index];
            final data = docItem.data() as Map<String, dynamic>;

            final name = (data['name'] ?? '').toString();
            final price = data['price'];
            final isAvailable = data['isAvailable'] as bool? ?? true;

            // Defence against a malformed document written by hand.
            if (name.isEmpty || price == null) {
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
                  isAvailable ? '৳ $price' : '৳ $price  ·  Retired',
                  style: TextStyle(
                    color: isAvailable ? Colors.black54 : Colors.grey,
                  ),
                ),
                trailing: CeoOnly(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(context, docItem.id, name, price);
                        case 'availability':
                          FirebaseFirestore.instance
                              .collection('docItems')
                              .doc(docItem.id)
                              .update({'isAvailable': !isAvailable});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit name / price'),
                      ),
                      PopupMenuItem(
                        value: 'availability',
                        child: Text(isAvailable ? 'Retire' : 'Relist'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    String name,
    Object? price,
  ) {
    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Document Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Document Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final priceText = priceController.text.trim();

                if (newName.isEmpty || priceText.isEmpty) return;

                final newPrice = int.tryParse(priceText);
                if (newPrice == null || newPrice < 0) return;

                Navigator.pop(dialogContext);

                await FirebaseFirestore.instance
                    .collection('docItems')
                    .doc(docId)
                    .update({'name': newName, 'price': newPrice});
              },
              child: const Text('Update'),
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
