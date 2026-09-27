import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// The whole catalogue, live, retired items included.
class WatchDocItems {
  const WatchDocItems(this._docItems);

  final DocItemRepository _docItems;

  Stream<List<DocItem>> call() => _docItems.watchAll();
}
