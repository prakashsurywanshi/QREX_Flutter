import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstallmentPayScreen extends ConsumerStatefulWidget {
  const InstallmentPayScreen({super.key, required this.installmentId});
  final int installmentId;

  @override
  ConsumerState<InstallmentPayScreen> createState() => _InstallmentPayScreenState();
}

class _InstallmentPayScreenState extends ConsumerState<InstallmentPayScreen> {
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _mode = 'cash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mode,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'cash'),
              decoration: const InputDecoration(labelText: 'Payment Mode'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () {}, child: const Text('Record Payment')),
          ],
        ),
      ),
    );
  }
}
