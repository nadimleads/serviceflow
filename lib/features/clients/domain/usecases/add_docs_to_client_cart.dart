import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Adds picked catalogue items to the client's cart and updates their total.
class AddDocsToClientCart {
  const AddDocsToClientCart(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, List<CartLine> additions) {
    return _clients.addToCart(clientId, additions);
  }
}
