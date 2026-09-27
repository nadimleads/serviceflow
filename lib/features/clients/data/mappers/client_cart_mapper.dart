import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/core/utils/safe_read.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';

/// The `clients/{id}/neededDocs/cartDocs` document shape.
class ClientCartMapper {
  const ClientCartMapper._();

  static ClientCart fromMap(Map<String, dynamic> data) {
    final lines = <String, CartLine>{};
    for (final entry in asMap(data['docs']).entries) {
      final line = asMap(entry.value);
      lines[entry.key] = CartLine(
        docItemId: entry.key,
        name: asString(line['name']),
        unitPrice: asInt(line['price']),
        quantity: asInt(line['quantity']),
      );
    }
    return ClientCart(lines: lines, totalAmount: asInt(data['totalAmount']));
  }

  /// The full document. `totalPrice` per line is derived, but the stored shape
  /// carries it alongside the inputs, so it is written for compatibility.
  static Map<String, dynamic> toMap(ClientCart cart) {
    return {
      'docs': {
        for (final line in cart.lines.values)
          line.docItemId: {
            'name': line.name,
            'quantity': line.quantity,
            'price': line.unitPrice,
            'totalPrice': line.lineTotal,
          },
      },
      'totalAmount': cart.totalAmount,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
