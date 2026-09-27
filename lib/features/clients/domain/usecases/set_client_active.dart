import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Flips the client's active flag. Inactive clients still appear in lists.
class SetClientActive {
  const SetClientActive(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, bool active) {
    return _clients.setActive(clientId, active);
  }
}
