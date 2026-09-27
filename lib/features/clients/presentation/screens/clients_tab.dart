import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_clients.dart';
import 'package:serviceflow/features/clients/presentation/screens/client_profile_screen.dart';

/// The All Clients list. Both roles see the same thing.
///
/// Ordering, pagination and the status chip land in a later stage.
class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key});

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  late final Stream<List<Client>> _clients;

  @override
  void initState() {
    super.initState();
    final watchClients = context.read<WatchClients>();
    _clients = watchClients();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Client>>(
      stream: _clients,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final clients = snapshot.data ?? const <Client>[];
        if (clients.isEmpty) {
          return const Center(child: Text('No clients yet'));
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Clients',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 218, 245, 255),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      return _ClientRow(client: clients[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final name = client.name.isEmpty ? 'Unknown' : client.name;
    final fileType = client.fileType.isEmpty ? '—' : client.fileType;
    final fileStatus = client.fileStatus.isEmpty ? '—' : client.fileStatus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientProfileScreen(
                clientId: client.id,
                clientName: name,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 255, 200),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$name • ($fileType)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fileStatus,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color.fromARGB(255, 44, 44, 44),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 30,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
