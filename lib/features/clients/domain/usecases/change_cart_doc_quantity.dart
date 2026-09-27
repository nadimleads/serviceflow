import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Moves one cart line's quantity by [delta]; zero removes the line.
class ChangeCartDocQuantity {
  const ChangeCartDocQuantity(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, String docItemId, int delta) {
    return _clients.changeCartQuantity(clientId, docItemId, delta);
  }
}
