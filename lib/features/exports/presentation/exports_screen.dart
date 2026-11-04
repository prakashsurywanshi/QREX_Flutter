import 'package:flutter/material.dart';

class ExportsScreen extends StatelessWidget {
  const ExportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.people), title: Text('Leads Export')),
          ListTile(leading: Icon(Icons.event), title: Text('Bookings Export')),
          ListTile(leading: Icon(Icons.payments), title: Text('Payments Export')),
        ],
      ),
    );
  }
}
