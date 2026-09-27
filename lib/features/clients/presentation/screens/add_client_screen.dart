import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/clients/domain/entities/new_client.dart';
import 'package:serviceflow/features/clients/domain/usecases/create_client.dart';
import 'package:serviceflow/features/clients/presentation/screens/client_profile_screen.dart';

/// The Add Client form. On success it replaces itself with the new profile.
class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
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
    final createClient = context.read<CreateClient>();

    final draft = NewClient(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      targetCountry: _countryController.text.trim(),
      fileDetails: _fileDetailsController.text.trim(),
      fileType: _fileTypeController.text.trim(),
      givenPapers: _givenPapersController.text.trim(),
    );

    try {
      final clientId = await createClient(draft);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientProfileScreen(
            clientId: clientId,
            clientName: draft.name,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create client')));
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
      appBar: AppBar(title: const Text('Add New Client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_nameController, 'Client Name'),
              _buildField(_addressController, 'Address'),
              _buildField(_emailController, 'Email'),
              _buildField(_phoneController, 'Phone'),
              _buildField(_countryController, 'Target Country'),
              _buildField(_fileDetailsController, 'File Details'),
              _buildField(_fileTypeController, 'File Type (Visit/Student)'),
              _buildField(_givenPapersController, 'Given Papers'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveClient,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Client'),
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
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
