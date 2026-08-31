import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/payment.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_pill.dart';
import 'payment_detail_sheet.dart';
import 'payment_form_sheet.dart';
import 'payments_controller.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(paymentsControllerProvider.notifier);
      if (ref.read(paymentsControllerProvider).payments.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsControllerProvider);
    final controller = ref.read(paymentsControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('payments') == true;
    final canEdit = can?.canEdit('payments') == true;
    final canDelete = can?.canDelete('payments') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Record Payment'),
            )
          : null,
      body: Column(
        children: [
          _SummaryStrip(summary: state.summary),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in ['All', ...paymentStatuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _statusFilter == s,
                      onSelected: (_) =>
                          setState(() => _statusFilter = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildList(context, state, controller, canEdit, canDelete),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PaymentsState state,
      PaymentsController controller, bool canEdit, bool canDelete) {
    if (state.loading && state.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.payments.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.load, child: const Text('Retry')),
      );
    }
    if (state.filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_outlined,
        message: 'No payments recorded',
        hint: 'Record your first payment.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        itemCount: state.filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final p = state.filtered[i];
          return _PaymentTile(
            payment: p,
            onTap: canEdit || canDelete
                ? () => _openDetail(context, p, canEdit, canDelete)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Payment p, bool canEdit,
      bool canDelete) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PaymentDetailSheet(
        initial: p,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () => ref.read(paymentsControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PaymentFormSheet(
        onSaved: () => ref.read(paymentsControllerProvider.notifier).load(),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final PaymentSummary summary;
  const _SummaryStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, double value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.inrLabel(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          cell('Receivable', summary.receivable, Icons.account_balance_wallet,
              theme.colorScheme.primary),
          cell('Collected', summary.received, Icons.wallet,
              Colors.green.shade700),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  const _PaymentTile({required this.payment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusPill(label: payment.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${payment.paymentId} · ${payment.propertyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.amountLabel ?? Formatters.inrLabel(payment.amount),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  Text(
                    '${payment.mode}${payment.txnId.isNotEmpty && payment.txnId != '—' ? ' · ${payment.txnId}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Due ${Formatters.date(payment.dueDate)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}