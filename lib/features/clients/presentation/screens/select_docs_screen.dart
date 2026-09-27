import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/watch_available_doc_items.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/usecases/add_docs_to_client_cart.dart';

/// Picks documents from the catalogue to add to a client's needed list.
///
/// Selections are held in memory until Confirm, which hands them to the cart
/// as [CartLine]s carrying the name and price shown at the moment of tapping.
class SelectDocsScreen extends StatefulWidget {
  const SelectDocsScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<SelectDocsScreen> createState() => _SelectDocsScreenState();
}

class _SelectDocsScreenState extends State<SelectDocsScreen> {
  late final Stream<List<DocItem>> _available;

  /// Chosen items and how many of each, keyed by catalogue item ID.
  final Map<String, _Selection> _selected = {};

  int get _total {
    return _selected.values.fold<int>(
      0,
      (sum, s) => sum + s.item.price * s.quantity,
    );
  }

  @override
  void initState() {
    super.initState();
    final watchAvailable = context.read<WatchAvailableDocItems>();
    _available = watchAvailable();
  }

  void _increment(DocItem item) {
    setState(() {
      final quantity = _selected[item.id]?.quantity ?? 0;
      _selected[item.id] = _Selection(item, quantity + 1);
    });
  }

  void _decrement(DocItem item) {
    setState(() {
      final quantity = _selected[item.id]?.quantity ?? 0;
      if (quantity <= 1) {
        _selected.remove(item.id);
      } else {
        _selected[item.id] = _Selection(item, quantity - 1);
      }
    });
  }

  Future<void> _confirmSelection() async {
    final addDocs = context.read<AddDocsToClientCart>();
    final additions = [
      for (final s in _selected.values)
        CartLine(
          docItemId: s.item.id,
          name: s.item.name,
          unitPrice: s.item.price,
          quantity: s.quantity,
        ),
    ];

    await addDocs(widget.clientId, additions);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Documents')),
      body: StreamBuilder<List<DocItem>>(
        stream: _available,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final quantity = _selected[item.id]?.quantity ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('Price: ${item.price} ৳'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed:
                                  quantity > 0 ? () => _decrement(item) : null,
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _increment(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total: $_total ৳',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _selected.isEmpty ? null : _confirmSelection,
                      child: const Text('Confirm'),
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
}

class _Selection {
  const _Selection(this.item, this.quantity);

  final DocItem item;
  final int quantity;
}
