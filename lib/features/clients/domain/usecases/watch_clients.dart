import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Every client, live. Ordering and paging are not applied yet.
class WatchClients {
  const WatchClients(this._clients);

  final ClientRepository _clients;

  Stream<List<Client>> call() => _clients.watchClients();
}
