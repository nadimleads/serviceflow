import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/core/utils/safe_read.dart';
import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';

/// The `docItems/{id}` document shape. The only place that knows its field
/// names, in either direction.
class DocItemMapper {
  const DocItemMapper._();

  /// Returns null for a document that cannot be shown: one written by hand
  /// with no name or no price. Callers drop those rather than crash a list.
  static DocItem? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = asString(data['name']);
    final rawPrice = data['price'];
    if (name.isEmpty || rawPrice == null) return null;

    return DocItem(
      id: doc.id,
      name: name,
      price: asInt(rawPrice),
      isAvailable: asBool(data['isAvailable'], fallback: true),
    );
  }

  static Map<String, dynamic> toCreateMap({
    required String name,
    required int price,
  }) {
    return {
      'name': name,
      'price': price,
      'isAvailable': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> toUpdateMap({
    required String name,
    required int price,
  }) {
    return {'name': name, 'price': price};
  }

  static Map<String, dynamic> availabilityToMap(bool isAvailable) {
    return {'isAvailable': isAvailable};
  }
}
