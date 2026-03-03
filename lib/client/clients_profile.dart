import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/client/select_doc_screen.dart';

class ClientsProfile extends StatefulWidget {
  const ClientsProfile({
    super.key,
    required this.clientsId,
    required this.clientsName,
  });

  final String clientsId;
  final String clientsName;

  @override
  State<ClientsProfile> createState() => _ClientsProfileState();
}

class _ClientsProfileState extends State<ClientsProfile> {
  Future<void> _markAsFullyPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Payment"),
          content: const Text(
            "Are you sure you want to mark this client as Fully Paid?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Confirm"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(widget.clientsId)
          .update({'paymentStatus': 'Fully Paid'});
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onEdit != null)
                  IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _editBasicInfo(
    BuildContext context,
    String name,
    String phone,
    String address,
    String country,
  ) async {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    final countryController = TextEditingController(text: country);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Basic Information"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: "Country"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('clients')
                    .doc(widget.clientsId)
                    .update({
                      'clientsname': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'targetCountry': countryController.text.trim(),
                    });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFileInfo(
    BuildContext context,
    String fileType,
    String fileStatus,
    String fileDetails,
    String givenPapers,
  ) async {
    final typeController = TextEditingController(text: fileType);
    final statusController = TextEditingController(text: fileStatus);
    final detailsController = TextEditingController(text: fileDetails);
    final givenPapersController = TextEditingController(text: givenPapers);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit File Information"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: "File Type"),
                ),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: "File Status"),
                ),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(labelText: "File Details"),
                ),
                TextField(
                  controller: givenPapersController,
                  decoration: const InputDecoration(labelText: "Given Papers"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('clients')
                    .doc(widget.clientsId)
                    .update({
                      'fileType': typeController.text.trim(),
                      'fileStatus': statusController.text.trim(),
                      'fileDetails': detailsController.text.trim(),
                      'givenPapers': givenPapersController.text.trim(),
                    });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPaymentInfo(
    BuildContext context,
    int totalAmount,
    int paidAmount,
    String paymentStatus,
  ) async {
    final paidController = TextEditingController(text: paidAmount.toString());

    final statusController = TextEditingController(text: paymentStatus);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Payment Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Total Paid Amount",
                ),
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: "Payment Status"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPaid = int.tryParse(paidController.text.trim()) ?? 0;

                await FirebaseFirestore.instance
                    .collection('clients')
                    .doc(widget.clientsId)
                    .update({
                      'paidAmount': newPaid,
                      'paymentStatus': statusController.text.trim(),
                    });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateDocQuantity(String docId, int change) async {
    final clientRef = FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientsId);

    final neededDocsRef = clientRef.collection('neededDocs').doc('cartDocs');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(neededDocsRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final docs = Map<String, dynamic>.from(data['docs'] ?? {});
      int currentTotal = data['totalAmount'] ?? 0;

      if (!docs.containsKey(docId)) return;

      final docData = Map<String, dynamic>.from(docs[docId]);

      int oldQty = docData['quantity'] ?? 0;
      final int price = docData['price'] ?? 0;

      int newQty = oldQty + change;

      if (newQty <= 0) {
        // Remove document completely
        currentTotal -= price * oldQty;
        docs.remove(docId);
      } else {
        docs[docId] = {
          'name': docData['name'],
          'quantity': newQty,
          'price': price,
          'totalPrice': newQty * price,
        };

        currentTotal += price * change;
      }

      transaction.update(neededDocsRef, {
        'docs': docs,
        'totalAmount': currentTotal,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      transaction.update(clientRef, {'totalAmount': currentTotal});
    });
  }

  //////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clientsName)),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('clients')
                .doc(widget.clientsId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Client not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final clientid = data['clientId'] ?? '';
          final isActive = data['active'] ?? '';
          final name = data['clientsname'] ?? '';
          final phone = data['phone'] ?? '';
          final address = data['address'] ?? '';
          final country = data['targetCountry'] ?? '';
          final fileType = data['fileType'] ?? '';
          final fileStatus = data['fileStatus'] ?? '';
          final givenPapers = data['givenPapers'] ?? '';
          final fileDetails = data['fileDetails'] ?? '';
          final totalAmount = data['totalAmount'] ?? 0;
          final paidAmount = data['paidAmount'] ?? 0;
          final paymentStatus = data['paymentStatus'] ?? 'Due';

          final payableAmount =
              (totalAmount - paidAmount) < 0 ? 0 : totalAmount - paidAmount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Basic Information Section
                _buildSectionCard(
                  title: "Basic Information",
                  onEdit: () {
                    _editBasicInfo(context, name, phone, address, country);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Active: ${isActive == true ? "Yes" : "No"}"),
                          Switch(
                            value: isActive == true,
                            onChanged: (value) async {
                              await FirebaseFirestore.instance
                                  .collection('clients')
                                  .doc(widget.clientsId)
                                  .update({'active': value});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Name: $name"),
                      const SizedBox(height: 6),
                      Text("ID: $clientid"),
                      const SizedBox(height: 6),
                      Text("Phone: $phone"),
                      const SizedBox(height: 6),
                      Text("Address: $address"),
                      const SizedBox(height: 6),
                      Text("Country: $country"),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 File Information Section
                _buildSectionCard(
                  title: "File Information",
                  onEdit: () {
                    _editFileInfo(
                      context,
                      fileType,
                      fileStatus,
                      fileDetails,
                      givenPapers,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("File Type: $fileType"),
                      const SizedBox(height: 6),
                      Text("File Status: $fileStatus"),
                      const SizedBox(height: 6),
                      Text("File Details: $fileDetails"),
                      const SizedBox(height: 6),
                      Text("Given Papers: $givenPapers"),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 Payment Information Section
                _buildSectionCard(
                  title: "Payment Information",
                  onEdit: () {
                    _editPaymentInfo(
                      context,
                      totalAmount,
                      paidAmount,
                      paymentStatus,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Amount: $totalAmount ৳"),
                      const SizedBox(height: 6),

                      Text("TOTAL Paid Amount: $paidAmount ৳"),
                      const SizedBox(height: 6),

                      Text(
                        "Payable Amount: $payableAmount ৳",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: payableAmount > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text("Payment Status: $paymentStatus"),

                      const SizedBox(height: 12),

                      /// ✅ Add This Button
                      if (paymentStatus != "Fully Paid")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _markAsFullyPaid,
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Mark as Fully Paid"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// 🔹 Needed Documents Section
                _buildSectionCard(
                  title: "Needed Documents",
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('clients')
                            .doc(widget.clientsId)
                            .collection('neededDocs')
                            .doc('cartDocs')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Column(
                          children: [
                            const Text("No documents added yet"),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SelectDocsScreen(
                                          clientId: widget.clientsId,
                                        ),
                                  ),
                                );
                              },
                              child: const Text("Add Needed Docs"),
                            ),
                          ],
                        );
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final docsMap = Map<String, dynamic>.from(
                        data['docs'] ?? {},
                      );
                      final totalAmount = data['totalAmount'] ?? 0;

                      if (docsMap.isEmpty) {
                        return Column(
                          children: [
                            const Text("No documents added yet"),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SelectDocsScreen(
                                          clientId: widget.clientsId,
                                        ),
                                  ),
                                );
                              },
                              child: const Text("Add Needed Docs"),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...docsMap.entries.map((entry) {
                            final docId = entry.key;
                            final docData = Map<String, dynamic>.from(
                              entry.value,
                            );

                            final name = docData['name'] ?? '';
                            final qty = docData['quantity'] ?? 0;
                            final price = docData['price'] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed:
                                            () => _updateDocQuantity(docId, -1),
                                      ),

                                      Text("x$qty"),

                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed:
                                            () => _updateDocQuantity(docId, 1),
                                      ),
                                    ],
                                  ),

                                  Text("${price * qty} ৳"),
                                ],
                              ),
                            );
                          }).toList(),

                          const Divider(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Total: $totalAmount ৳",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SelectDocsScreen(
                                        clientId: widget.clientsId,
                                      ),
                                ),
                              );
                            },
                            child: const Text("Add More Docs"),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 Comments Section
                _buildSectionCard(
                  title: "Comments",
                  child: Column(
                    children: [
                      const Text("No comments yet"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Add Comment"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
