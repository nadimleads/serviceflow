import 'package:serviceflow/features/catalogue/domain/entities/doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';

/// Only the items a client can currently be billed for, live.
class WatchAvailableDocItems {
  const WatchAvailableDocItems(this._docItems);

  final DocItemRepository _docItems;

  Stream<List<DocItem>> call() => _docItems.watchAvailable();
}
