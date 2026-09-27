import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// Renames or reprices an item. CEO only (enforced by rules, hidden by UI).
class UpdateDocItem {
  const UpdateDocItem(this._docItems);

  final DocItemRepository _docItems;

  Future<void> call(String id, {required String name, required int price}) {
    return _docItems.update(id, name: name, price: price);
  }
}
