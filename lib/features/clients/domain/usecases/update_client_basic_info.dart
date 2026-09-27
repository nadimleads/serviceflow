import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Saves the Basic Information card: name, phone, address, country.
class UpdateClientBasicInfo {
  const UpdateClientBasicInfo(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, ClientBasicInfo info) {
    return _clients.updateBasicInfo(clientId, info);
  }
}
