import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewDoc extends StatefulWidget {
  const AddNewDoc({super.key});

  @override
  State<AddNewDoc> createState() => _AddNewDocState();
}

class _AddNewDocState extends State<AddNewDoc> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() => _isSaving = true);

    final String newItemName = _nameController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('docItems').add({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        // 'createdBy': 'createdBy',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New item added: $newItemName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context); // back to dashboard
    } catch (e) {
      debugPrint("Failed to add item: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add menu item")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("New Document Item"),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Add a Documnet here",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fill in the details below",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Documnet Name",
                        prefixIcon: const Icon(Icons.format_list_bulleted_add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator:
                          (v) =>
                              (v?.trim().isEmpty ?? true) ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        labelText: "Price (BDT)",
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Required";
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return "Enter valid amount";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveItem,
                        icon:
                            _isSaving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.save, size: 20),
                        label:
                            _isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : const Text(
                                  "Save Item",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
