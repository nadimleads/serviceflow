import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serviceflow/client/clients_profile.dart';

class AddNewClient extends StatefulWidget {
  const AddNewClient({super.key});

  @override
  State<AddNewClient> createState() => _AddNewClientState();
}

class _AddNewClientState extends State<AddNewClient> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _fileDetailsController = TextEditingController();
  final _fileTypeController = TextEditingController();
  final _givenPapersController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    //Generate Custom ID fro Client
    try {
      String newClientId = '';
      // set and get is from transaction, we must use Firestore transaction internally — otherwise two clicks at the same time can generate duplicate IDs
      await FirebaseFirestore.instance.runTransaction((ctx) async {
        final counterDoc = FirebaseFirestore.instance
            .collection('counters')
            .doc('clientCounter');
        final snapshot = await ctx.get(counterDoc);
        int lastId = 0;
        if (snapshot.exists) {
          lastId = snapshot.data()?['lastId'] ?? 0;
        }

        final nextId = lastId + 1;
        newClientId = 'C${nextId.toString().padLeft(3, '0')}';
        ctx.set(counterDoc, {'lastId': nextId});
        final clientDoc = FirebaseFirestore.instance
            .collection('clients')
            .doc(newClientId);

        ctx.set(clientDoc, {
          'clientId': newClientId,
          'clientsname': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'targetCountry': _countryController.text.trim(),
          'fileDetails': _fileDetailsController.text.trim(),
          'fileType': _fileTypeController.text.trim(),
          'fileStatus': 'File Opened',
          'givenPapers': _givenPapersController.text.trim(),
          'paymentStatus': 'Due',
          'totalAmount': 0,
          'paidAmount': 0,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => ClientsProfile(
                clientsId: newClientId,
                clientsName: newClientId,
                //clientsName this is unnecessary i think(need to fix later in clients proile)
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to create client")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _fileDetailsController.dispose();
    _fileTypeController.dispose();
    _givenPapersController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Client")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_nameController, "Client Name"),
              _buildField(_addressController, "Address"),
              _buildField(_emailController, "Email"),
              _buildField(_phoneController, "Phone"),
              _buildField(_countryController, "Target Country"),
              _buildField(_fileDetailsController, "File Details"),
              _buildField(_fileTypeController, "File Type (Visit/Student)"),
              _buildField(_givenPapersController, "Given Papers"),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveClient,
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Create Client"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) =>
                value == null || value.trim().isEmpty ? "Required" : null,
      ),
    );
  }
}
