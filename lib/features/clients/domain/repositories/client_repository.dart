import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/entities/new_client.dart';

/// Clients and their needed-documents cart.
///
/// One interface for both because a cart write also moves the client's total,
/// and only the implementation knows how to do that atomically.
abstract interface class ClientRepository {
  Stream<List<Client>> watchClients();

  /// Emits null when the client does not exist, or is deleted mid-stream.
  Stream<Client?> watchClient(String clientId);

  /// Creates the client and returns its ID.
  Future<String> createClient(NewClient draft);

  Future<void> updateBasicInfo(String clientId, ClientBasicInfo info);
  Future<void> updateFileInfo(String clientId, ClientFileInfo info);
  Future<void> updatePaymentInfo(String clientId, ClientPaymentInfo info);
  Future<void> setActive(String clientId, bool active);
  Future<void> markFullyPaid(String clientId);

  /// Emits null until the client has a cart at all.
  Stream<ClientCart?> watchCart(String clientId);

  /// Adds lines to the cart (see `ClientCart.merge`) and updates the client's
  /// total in the same write.
  Future<void> addToCart(String clientId, List<CartLine> additions);

  /// See `ClientCart.adjustQuantity`. A no-op when the line is not in the cart.
  Future<void> changeCartQuantity(String clientId, String docItemId, int delta);
}
