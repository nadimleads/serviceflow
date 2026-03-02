import 'package:flutter/material.dart';

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
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clientsName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Basic Information Section
            _buildSectionCard(
              title: "Basic Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Phone: "),
                  SizedBox(height: 6),
                  Text("Address: "),
                  SizedBox(height: 6),
                  Text("Country: "),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 File Information Section
            _buildSectionCard(
              title: "File Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("File Type: "),
                  SizedBox(height: 6),
                  Text("File Status: "),
                  SizedBox(height: 6),
                  Text("File Details: "),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Payment Information Section
            _buildSectionCard(
              title: "Payment Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Total Amount: "),
                  SizedBox(height: 6),
                  Text("Payment Status: "),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Needed Documents Section
            _buildSectionCard(
              title: "Needed Documents",
              child: Column(
                children: [
                  const Text("No documents added yet"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Add Needed Docs"),
                  ),
                ],
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
      ),
    );
  }
}
