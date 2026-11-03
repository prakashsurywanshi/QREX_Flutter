import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/commission.dart';
import '../../../core/utils/formatters.dart';
import 'commissions_controller.dart';

class CommissionsScreen extends ConsumerStatefulWidget {
  const CommissionsScreen({super.key});

  @override
  ConsumerState<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends ConsumerState<CommissionsScreen> {
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commissionsListProvider((page: 1, status: _status == 'All' ? null : _status, agentId: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissions'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _status,
            onSelected: (v) => setState(() => _status = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'approved', child: Text('Approved')),
              PopupMenuItem(value: 'paid', child: Text('Paid')),
              PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: async.when(
        data: (data) {
          final items = data.items;
          final summary = data.summary;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(title: 'Pending', amount: (summary['pending'] as num?)?.toDouble() ?? 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: 'Approved', amount: (summary['approved'] as num?)?.toDouble() ?? 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: 'Paid', amount: (summary['paid'] as num?)?.toDouble() ?? 0)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(c.agentName ?? 'Agent'),
                        subtitle: Text('${c.splitType ?? '-'} • ${c.status?.toUpperCase() ?? '-'}'),
                        trailing: Text(formatCurrency(c.commissionAmount ?? 0)),
                        onTap: () => context.push('/commissions/${c.id}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.amount});

  final String title;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(formatCurrency(amount), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
