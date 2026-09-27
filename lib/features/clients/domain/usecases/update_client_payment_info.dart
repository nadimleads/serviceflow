import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Saves the Payment Information card: total paid so far and the status text.
class UpdateClientPaymentInfo {
  const UpdateClientPaymentInfo(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId, ClientPaymentInfo info) {
    return _clients.updatePaymentInfo(clientId, info);
  }
}
