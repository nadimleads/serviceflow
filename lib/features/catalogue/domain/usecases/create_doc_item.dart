import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// Adds a new item to the catalogue. Open to both roles.
class CreateDocItem {
  const CreateDocItem(this._docItems);

  final DocItemRepository _docItems;

  Future<void> call({required String name, required int price}) {
    return _docItems.create(name: name, price: price);
  }
}
