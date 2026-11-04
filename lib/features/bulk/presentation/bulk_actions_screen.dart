import 'package:flutter/material.dart';

class BulkActionsScreen extends StatelessWidget {
  const BulkActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Actions')),
      body: const Center(child: Text('Bulk Assign, Update, Export')),
    );
  }
}
