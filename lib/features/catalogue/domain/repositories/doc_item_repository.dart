import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';

/// The document catalogue ("menu"). Both roles read and create; only the CEO
/// edits, retires or relists — `firestore.rules` is what enforces that.
abstract interface class DocItemRepository {
  /// Every item, retired ones included.
  Stream<List<DocItem>> watchAll();

  /// Only items that can currently be added to a client.
  Stream<List<DocItem>> watchAvailable();

  Future<void> create({required String name, required int price});

  Future<void> update(String id, {required String name, required int price});

  Future<void> setAvailability(String id, bool isAvailable);
}
