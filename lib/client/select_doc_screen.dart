import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectDocsScreen extends StatefulWidget {
  final String clientId;

  const SelectDocsScreen({super.key, required this.clientId});

  @override
  State<SelectDocsScreen> createState() => _SelectDocsScreenState();
}

class _SelectDocsScreenState extends State<SelectDocsScreen> {
  final Map<String, int> selectedQuantities = {};

  int get totalAmount {
    int total = 0;

    selectedQuantities.forEach((docId, qty) {
      final price = _docPrices[docId] ?? 0;
      total += price * qty;
    });

    return total;
  }

  // Cache price only (minimal memory)
  final Map<String, int> _docPrices = {};
  final Map<String, String> _docNames = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Documents")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('docItems')
                .where('isAvailable', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              /// 🔹 Docs List
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final docId = doc.id;
                    final name = doc['name'] ?? '';
                    final price = (doc['price'] as num?)?.toInt() ?? 0;

                    _docPrices[docId] = price;
                    _docNames[docId] = name;

                    final qty = selectedQuantities[docId] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text("Price: $price ৳"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed:
                                  qty > 0
                                      ? () {
                                        setState(() {
                                          if (qty == 1) {
                                            selectedQuantities.remove(docId);
                                          } else {
                                            selectedQuantities[docId] = qty - 1;
                                          }
                                        });
                                      }
                                      : null,
                            ),

                            Text(qty.toString()),

                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  selectedQuantities[docId] = qty + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// 🔹 Bottom Confirm Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Total: $totalAmount ৳",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          selectedQuantities.isEmpty ? null : _confirmSelection,
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmSelection() async {
    final clientRef = FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId);

    final neededDocsRef = clientRef.collection('neededDocs').doc('cartDocs');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(neededDocsRef);

      Map<String, dynamic> existingDocs = {};
      int existingTotal = 0;

      if (snapshot.exists) {
        existingDocs = Map<String, dynamic>.from(
          snapshot.data()?['docs'] ?? {},
        );
        existingTotal = snapshot.data()?['totalAmount'] ?? 0;
      }

      int addedTotal = 0;

      // Merge new selections into existing docs
      selectedQuantities.forEach((docId, qty) {
        final price = _docPrices[docId] ?? 0;

        if (existingDocs.containsKey(docId)) {
          final oldQty = existingDocs[docId]['quantity'] ?? 0;
          final newQty = oldQty + qty;

          existingDocs[docId] = {
            'name': _docNames[docId] ?? '',
            'quantity': newQty,
            'price': price,
            'totalPrice': newQty * price,
          };
        } else {
          existingDocs[docId] = {
            'name': _docNames[docId] ?? '',
            'quantity': qty,
            'price': price,
            'totalPrice': qty * price,
          };
        }

        addedTotal += price * qty;
      });

      final updatedTotal = existingTotal + addedTotal;

      transaction.set(neededDocsRef, {
        'docs': existingDocs,
        'totalAmount': updatedTotal,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(clientRef, {'totalAmount': updatedTotal});
    });

    Navigator.pop(context);
  }
}
