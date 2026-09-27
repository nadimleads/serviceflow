import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/usecases/change_cart_doc_quantity.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_client_cart.dart';
import 'package:serviceflow/features/clients/presentation/screens/select_docs_screen.dart';
import 'package:serviceflow/features/clients/presentation/widgets/section_card.dart';

/// The Needed Documents card on a client profile: the cart lines with +/−
/// controls, the running total, and the way into the picker.
class NeededDocsSection extends StatefulWidget {
  const NeededDocsSection({super.key, required this.clientId});

  final String clientId;

  @override
  State<NeededDocsSection> createState() => _NeededDocsSectionState();
}

class _NeededDocsSectionState extends State<NeededDocsSection> {
  late final Stream<ClientCart?> _cart;

  @override
  void initState() {
    super.initState();
    final watchCart = context.read<WatchClientCart>();
    _cart = watchCart(widget.clientId);
  }

  void _openPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectDocsScreen(clientId: widget.clientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changeQuantity = context.read<ChangeCartDocQuantity>();

    return SectionCard(
      title: 'Needed Documents',
      child: StreamBuilder<ClientCart?>(
        stream: _cart,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cart = snapshot.data;
          if (cart == null || cart.isEmpty) {
            return Column(
              children: [
                const Text('No documents added yet'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _openPicker(context),
                  child: const Text('Add Needed Docs'),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in cart.lines.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          line.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => changeQuantity(
                              widget.clientId,
                              line.docItemId,
                              -1,
                            ),
                          ),
                          Text('x${line.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => changeQuantity(
                              widget.clientId,
                              line.docItemId,
                              1,
                            ),
                          ),
                        ],
                      ),
                      Text('${line.lineTotal} ৳'),
                    ],
                  ),
                ),

              const Divider(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${cart.totalAmount} ৳',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () => _openPicker(context),
                child: const Text('Add More Docs'),
              ),
            ],
          );
        },
      ),
    );
  }
}
