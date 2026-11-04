import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import 'commissions_controller.dart';

class CommissionDetailScreen extends ConsumerWidget {
  const CommissionDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(commissionDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text('Commission #$id')),
      body: async.when(
        data: (c) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent: ${c.agentName ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Status: ${c.status ?? '-'}'),
                    Text('Type: ${c.commissionType ?? '-'}'),
                    Text('Split: ${c.splitType ?? '-'}'),
                    const Divider(),
                    Text('Base Amount: ${formatCurrency(c.baseAmount ?? 0)}'),
                    Text('Commission: ${formatCurrency(c.commissionAmount ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
            if (c.splits.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Splits', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...c.splits.map((s) => ListTile(
                            dense: true,
                            title: Text(s.userName ?? 'User'),
                            subtitle: Text('${s.role ?? '-'} • ${s.sharePercentage ?? 0}%'),
                            trailing: Text(formatCurrency(s.shareAmount ?? 0)),
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
