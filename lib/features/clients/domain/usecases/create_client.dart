import 'package:serviceflow/features/clients/domain/entities/new_client.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// Creates a client from the form's draft and returns the new client's ID.
class CreateClient {
  const CreateClient(this._clients);

  final ClientRepository _clients;

  Future<String> call(NewClient draft) => _clients.createClient(draft);
}
