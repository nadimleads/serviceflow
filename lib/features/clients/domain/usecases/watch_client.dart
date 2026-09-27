import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// One client, live. Emits null once the client no longer exists.
class WatchClient {
  const WatchClient(this._clients);

  final ClientRepository _clients;

  Stream<Client?> call(String clientId) => _clients.watchClient(clientId);
}
