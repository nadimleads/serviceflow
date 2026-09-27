import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/usecases/mark_client_fully_paid.dart';
import 'package:serviceflow/features/clients/domain/usecases/set_client_active.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_basic_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_file_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_payment_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_client.dart';
import 'package:serviceflow/features/clients/presentation/widgets/edit_fields_dialog.dart';
import 'package:serviceflow/features/clients/presentation/widgets/needed_docs_section.dart';
import 'package:serviceflow/features/clients/presentation/widgets/section_card.dart';

/// A client's full record: identity, file, money, needed documents, comments.
///
/// Streams the client document once for the whole screen. Each section is a
/// plain widget that receives the [Client] and reads its use case from context.
class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;

  /// Shown in the app bar. The streamed document carries the name too; this
  /// only avoids a blank title while the first snapshot is in flight.
  final String clientName;

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late final Stream<Client?> _client;

  @override
  void initState() {
    super.initState();
    final watchClient = context.read<WatchClient>();
    _client = watchClient(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clientName)),
      body: StreamBuilder<Client?>(
        stream: _client,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final client = snapshot.data;
          if (client == null) {
            return const Center(child: Text('Client not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BasicInfoSection(client: client),
                const SizedBox(height: 16),
                _FileInfoSection(client: client),
                const SizedBox(height: 16),
                _PaymentSection(client: client),
                NeededDocsSection(clientId: client.id),
                const SizedBox(height: 16),
                const _CommentsSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final updateBasicInfo = context.read<UpdateClientBasicInfo>();
    final setActive = context.read<SetClientActive>();

    return SectionCard(
      title: 'Basic Information',
      onEdit: () => showEditFieldsDialog(
        context,
        title: 'Edit Basic Information',
        fields: [
          EditField('Name', client.name),
          EditField('Phone', client.phone),
          EditField('Address', client.address),
          EditField('Country', client.targetCountry),
        ],
        onSave: (values) => updateBasicInfo(
          client.id,
          ClientBasicInfo(
            name: values[0],
            phone: values[1],
            address: values[2],
            targetCountry: values[3],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active: ${client.active ? "Yes" : "No"}'),
              Switch(
                value: client.active,
                onChanged: (value) => setActive(client.id, value),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Name: ${client.name}'),
          const SizedBox(height: 6),
          Text('ID: ${client.code}'),
          const SizedBox(height: 6),
          Text('Phone: ${client.phone}'),
          const SizedBox(height: 6),
          Text('Address: ${client.address}'),
          const SizedBox(height: 6),
          Text('Country: ${client.targetCountry}'),
        ],
      ),
    );
  }
}

class _FileInfoSection extends StatelessWidget {
  const _FileInfoSection({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final updateFileInfo = context.read<UpdateClientFileInfo>();

    return SectionCard(
      title: 'File Information',
      onEdit: () => showEditFieldsDialog(
        context,
        title: 'Edit File Information',
        fields: [
          EditField('File Type', client.fileType),
          EditField('File Status', client.fileStatus),
          EditField('File Details', client.fileDetails),
          EditField('Given Papers', client.givenPapers),
        ],
        onSave: (values) => updateFileInfo(
          client.id,
          ClientFileInfo(
            fileType: values[0],
            fileStatus: values[1],
            fileDetails: values[2],
            givenPapers: values[3],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File Type: ${client.fileType}'),
          const SizedBox(height: 6),
          Text('File Status: ${client.fileStatus}'),
          const SizedBox(height: 6),
          Text('File Details: ${client.fileDetails}'),
          const SizedBox(height: 6),
          Text('Given Papers: ${client.givenPapers}'),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.client});

  final Client client;

  Future<void> _confirmFullyPaid(
    BuildContext context,
    MarkClientFullyPaid markFullyPaid,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text(
            'Are you sure you want to mark this client as Fully Paid?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes, Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await markFullyPaid(client.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatePaymentInfo = context.read<UpdateClientPaymentInfo>();
    final markFullyPaid = context.read<MarkClientFullyPaid>();
    final payable = client.payableAmount;

    return SectionCard(
      title: 'Payment Information',
      onEdit: () => showEditFieldsDialog(
        context,
        title: 'Edit Payment Information',
        fields: [
          EditField(
            'Total Paid Amount',
            '${client.paidAmount}',
            keyboardType: TextInputType.number,
          ),
          EditField('Payment Status', client.paymentStatus),
        ],
        onSave: (values) => updatePaymentInfo(
          client.id,
          ClientPaymentInfo(
            paidAmount: int.tryParse(values[0]) ?? 0,
            paymentStatus: values[1],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Amount: ${client.totalAmount} ৳'),
          const SizedBox(height: 6),
          Text('TOTAL Paid Amount: ${client.paidAmount} ৳'),
          const SizedBox(height: 6),
          Text(
            'Payable Amount: $payable ৳',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: payable > 0 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text('Payment Status: ${client.paymentStatus}'),
          const SizedBox(height: 12),
          if (!client.isFullyPaid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmFullyPaid(context, markFullyPaid),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Fully Paid'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder until the Work Progress feed lands (BUILD_PLAN stage 6).
class _CommentsSection extends StatelessWidget {
  const _CommentsSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Comments',
      child: Column(
        children: [
          const Text('No comments yet'),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: const Text('Add Comment')),
        ],
      ),
    );
  }
}
