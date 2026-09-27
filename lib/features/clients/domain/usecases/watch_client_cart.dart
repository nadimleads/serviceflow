import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// The client's needed-documents cart, live. Null until one exists.
class WatchClientCart {
  const WatchClientCart(this._clients);

  final ClientRepository _clients;

  Stream<ClientCart?> call(String clientId) => _clients.watchCart(clientId);
}
