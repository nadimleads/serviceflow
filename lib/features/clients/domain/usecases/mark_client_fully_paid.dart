import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Sets the payment status to fully paid. Does not move [paidAmount].
class MarkClientFullyPaid {
  const MarkClientFullyPaid(this._clients);

  final ClientRepository _clients;

  Future<void> call(String clientId) => _clients.markFullyPaid(clientId);
}
