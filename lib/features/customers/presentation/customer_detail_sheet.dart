// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'customer_form_sheet.dart';
import 'customers_controller.dart';

class CustomerDetailSheet extends ConsumerStatefulWidget {
  final Customer initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const CustomerDetailSheet({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.canDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<CustomerDetailSheet> createState() =>
      _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends ConsumerState<CustomerDetailSheet> {
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.initial;
  }

  Future<void> _edit() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => CustomerFormSheet(
        initial: _customer,
        onSaved: () {
          widget.onChanged();
        },
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete customer?',
      content:
          '${_customer!.name} (${_customer!.customerId}) will be removed.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(customersControllerProvider.notifier)
          .deleteCustomer(_customer!.id);
      widget.onChanged();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Customer deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _customer!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: c.name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.customerId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(c.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: c.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                  avatar: const Icon(Icons.phone, size: 16),
                  label: Text(c.phone),
                  onPressed: () {}),
              if (c.email != null && c.email!.isNotEmpty)
                ActionChip(
                    avatar: const Icon(Icons.mail_outline, size: 16),
                    label: Text(c.email!),
                    onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.canEdit)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: _edit,
                ),
              ],
            ),
          if (widget.canDelete)
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
            ),
          const SizedBox(height: 4),
          SectionCard(
            title: 'Details',
            child: Column(
              children: [
                for (final (k, v) in _rows())
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(k, style: theme.textTheme.bodySmall),
                        Flexible(
                          child: Text(v,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _rows() {
    final c = _customer!;
    return [
      if (c.type != null && c.type!.isNotEmpty) ('Type', c.type!),
      if (c.city != null && c.city!.isNotEmpty) ('City', c.city!),
      if (c.requirements != null && c.requirements!.isNotEmpty)
        ('Requirements', c.requirements!),
      if (c.agentName != null) ('Agent', c.agentName!),
      if (c.propertyCount != null) ('Properties', '${c.propertyCount}'),
      if (c.totalValue != null)
        ('Total value', Formatters.inrLabel(c.totalValue!)),
      ('Created', Formatters.date(c.createdAt)),
    ];
  }
}