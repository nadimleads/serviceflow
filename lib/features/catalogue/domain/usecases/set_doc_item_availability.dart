import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// Retires (false) or relists (true) an item. CEO only.
class SetDocItemAvailability {
  const SetDocItemAvailability(this._docItems);

  final DocItemRepository _docItems;

  Future<void> call(String id, bool isAvailable) {
    return _docItems.setAvailability(id, isAvailable);
  }
}
