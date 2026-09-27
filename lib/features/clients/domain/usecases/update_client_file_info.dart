import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Saves the File Information card: type, status, details, given papers.
class UpdateClientFileInfo {
  const UpdateClientFileInfo(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, ClientFileInfo info) {
    return _clients.updateFileInfo(clientId, info);
  }
}
