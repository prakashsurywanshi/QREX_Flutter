import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import 'payment_plans_controller.dart';

class PaymentPlansScreen extends ConsumerWidget {
  const PaymentPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentPlansListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Plans')),
      body: async.when(
        data: (plans) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = plans[i];
            return Card(
              child: ListTile(
                title: Text(p.planName ?? 'Plan'),
                subtitle: Text('${p.planType ?? '-'} • ${p.installments.length} installments'),
                trailing: Text(formatCurrency(p.totalAmount ?? 0)),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
