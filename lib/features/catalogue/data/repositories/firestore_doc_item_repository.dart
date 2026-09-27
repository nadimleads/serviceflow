import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/features/catalogue/data/mappers/doc_item_mapper.dart';
import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// [DocItemRepository] backed by the Firestore `docItems` collection.
class FirestoreDocItemRepository implements DocItemRepository {
  FirestoreDocItemRepository(this._db);

  final FirebaseFirestore _db;

  static const _collection = 'docItems';

  CollectionReference<Map<String, dynamic>> get _items {
    return _db.collection(_collection);
  }

  @override
  Stream<List<DocItem>> watchAll() => _items.snapshots().map(_toItems);

  @override
  Stream<List<DocItem>> watchAvailable() {
    return _items
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(_toItems);
  }

  @override
  Future<void> create({required String name, required int price}) async {
    await _items.add(DocItemMapper.toCreateMap(name: name, price: price));
  }

  @override
  Future<void> update(String id, {required String name, required int price}) {
    return _items.doc(id).update(
      DocItemMapper.toUpdateMap(name: name, price: price),
    );
  }

  @override
  Future<void> setAvailability(String id, bool isAvailable) {
    return _items.doc(id).update(DocItemMapper.availabilityToMap(isAvailable));
  }

  static List<DocItem> _toItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(DocItemMapper.fromDoc).whereType<DocItem>().toList();
  }
}
