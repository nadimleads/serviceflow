import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/auth/presentation/widgets/ceo_only.dart';
import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/set_doc_item_availability.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/update_doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/watch_doc_items.dart';

/// The catalogue body — the "menu" of documents and their prices.
///
/// Body only, no Scaffold: it is hosted by the Doc List tab in the shell.
///
/// Both roles may CREATE items (the shell's FAB). Only the CEO may edit,
/// retire or relist one, so every mutating affordance lives inside the
/// [CeoOnly] popup menu. An Employee sees the list and nothing else.
class DocListView extends StatefulWidget {
  const DocListView({super.key});

  @override
  State<DocListView> createState() => _DocListViewState();
}

class _DocListViewState extends State<DocListView> {
  late final Stream<List<DocItem>> _items;

  @override
  void initState() {
    super.initState();
    final watchDocItems = context.read<WatchDocItems>();
    _items = watchDocItems();
  }

  void _showEditDialog(BuildContext context, DocItem item) {
    final updateDocItem = context.read<UpdateDocItem>();
    showDialog<void>(
      context: context,
      builder: (_) => _EditDocItemDialog(
        item: item,
        onSave: (name, price) => updateDocItem(item.id, name: name, price: price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setAvailability = context.read<SetDocItemAvailability>();

    return StreamBuilder<List<DocItem>>(
      stream: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? const <DocItem>[];
        if (items.isEmpty) {
          return const Center(
            child: Text('No documents yet', style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: item.isAvailable ? Colors.white : Colors.grey.shade200,
              child: ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isAvailable ? Colors.black : Colors.grey,
                    decoration:
                        item.isAvailable ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  item.isAvailable
                      ? '৳ ${item.price}'
                      : '৳ ${item.price}  ·  Retired',
                  style: TextStyle(
                    color: item.isAvailable ? Colors.black54 : Colors.grey,
                  ),
                ),
                trailing: CeoOnly(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(context, item);
                        case 'availability':
                          setAvailability(item.id, !item.isAvailable);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit name / price'),
                      ),
                      PopupMenuItem(
                        value: 'availability',
                        child: Text(item.isAvailable ? 'Retire' : 'Relist'),
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
}

/// Name and price editor. Owns its controllers so they are disposed with it.
class _EditDocItemDialog extends StatefulWidget {
  const _EditDocItemDialog({required this.item, required this.onSave});

  final DocItem item;
  final Future<void> Function(String name, int price) onSave;

  @override
  State<_EditDocItemDialog> createState() => _EditDocItemDialogState();
}

class _EditDocItemDialogState extends State<_EditDocItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: '${widget.item.price}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final newName = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (newName.isEmpty || priceText.isEmpty) return;

    final newPrice = int.tryParse(priceText);
    if (newPrice == null || newPrice < 0) return;

    Navigator.pop(context);
    await widget.onSave(newName, newPrice);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Document Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Document Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _update, child: const Text('Update')),
      ],
    );
  }
}
