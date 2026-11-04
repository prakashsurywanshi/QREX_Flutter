import 'package:flutter/material.dart';

class AuditDetailScreen extends StatelessWidget {
  const AuditDetailScreen({super.key, required this.log});
  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action: ${log['action'] ?? ''}'),
            const SizedBox(height: 8),
            Text('User: ${log['user_id'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Date: ${log['created_at'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}
