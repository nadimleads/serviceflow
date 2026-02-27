import 'package:flutter/material.dart';

class ClientsProfile extends StatefulWidget {
  const ClientsProfile({
    super.key,
    required this.clientsId,
    required this.clientsName,
  });

  final String clientsId;
  final String clientsName;

  @override
  State<ClientsProfile> createState() => _ClientsProfileState();
}

class _ClientsProfileState extends State<ClientsProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientsName),
        actions: [const SizedBox(width: 20)],
      ),

      body: Text('No items available right now'),
    );
  }
}
