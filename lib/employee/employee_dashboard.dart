import 'package:flutter/material.dart';

class TeammateDashboard extends StatefulWidget {
  const TeammateDashboard({super.key});

  @override
  State<TeammateDashboard> createState() {
    return _TeammateDashboard();
  }
}

class _TeammateDashboard extends State<TeammateDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Teammate Dashboard')));
  }
}
