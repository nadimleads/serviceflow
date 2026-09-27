import 'package:flutter/material.dart';

/// One labelled text field in an [EditFieldsDialog].
class EditField {
  const EditField(this.label, this.initialValue, {this.keyboardType});

  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
}

/// Opens a dialog of text fields for one card of the client profile.
///
/// Save awaits [onSave] with the trimmed values, in [fields] order, and only
/// then closes the dialog — so a failed write leaves the form on screen.
Future<void> showEditFieldsDialog(
  BuildContext context, {
  required String title,
  required List<EditField> fields,
  required Future<void> Function(List<String> values) onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => EditFieldsDialog(title: title, fields: fields, onSave: onSave),
  );
}

class EditFieldsDialog extends StatefulWidget {
  const EditFieldsDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
  });

  final String title;
  final List<EditField> fields;
  final Future<void> Function(List<String> values) onSave;

  @override
  State<EditFieldsDialog> createState() => _EditFieldsDialogState();
}

class _EditFieldsDialogState extends State<EditFieldsDialog> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final field in widget.fields)
        TextEditingController(text: field.initialValue),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave([for (final c in _controllers) c.text.trim()]);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.fields.length; i++)
              TextField(
                controller: _controllers[i],
                keyboardType: widget.fields[i].keyboardType,
                decoration: InputDecoration(labelText: widget.fields[i].label),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
