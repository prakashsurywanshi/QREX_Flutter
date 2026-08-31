// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/payment.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'payments_controller.dart';

class PaymentDetailSheet extends ConsumerStatefulWidget {
  final Payment initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const PaymentDetailSheet({
    super.key,
    required this.initial,
    this.canEdit = false,
    this.canDelete = false,
    required this.onChanged,
  });

  @override
  ConsumerState<PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends ConsumerState<PaymentDetailSheet> {
  late final bool _editing;
  String? _status;
  String? _mode;
  final _txn = TextEditingController();
  String? _paidDate;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _editing = widget.canEdit;
    _status = p.status;
    _mode = p.mode;
    _txn.text = p.txnId == '—' ? '' : p.txnId;
    _paidDate = p.paidDate;
    _dueDate = p.dueDate;
  }

  @override
  void dispose() {
    _txn.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPaid) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(isPaid ? (_paidDate ?? '') : (_dueDate ?? '')) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) {
      final s =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isPaid) {
          _paidDate = s;
        } else {
          _dueDate = s;
        }
      });
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(paymentsRepositoryProvider).update(widget.initial.id, {
        'status': _status,
        'mode': _mode,
        'txn_id': _txn.text.trim().isEmpty ? '—' : _txn.text.trim(),
        'paid_date': _paidDate ?? '',
        'due_date': _dueDate ?? '',
      });
      widget.onChanged();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Payment updated.'),
          behavior: SnackBarBehavior.floating,
        ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(context,
        title: 'Delete Payment?',
        content:
            'Delete payment ${widget.initial.paymentId} for ${widget.initial.customerName}?',
        confirmLabel: 'Delete');
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(paymentsRepositoryProvider).delete(widget.initial.id);
      widget.onChanged();
      if (mounted) navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Payment deleted.'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.initial;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.customerName, style: theme.textTheme.titleLarge),
                    Text(p.paymentId,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              StatusPill(label: p.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.amountLabel ?? Formatters.inrLabel(p.amount),
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(theme, 'Property', p.propertyName),
                _row(theme, 'Mode', p.mode.isEmpty ? '—' : p.mode),
                _row(theme, 'Transaction', p.txnId),
                _row(theme, 'Due Date', Formatters.date(p.dueDate)),
                _row(theme, 'Paid Date', Formatters.date(p.paidDate)),
                _row(theme, 'Recorded', Formatters.date(p.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_editing) ...[
            SectionCard(
              title: 'Update Payment',
              child: Column(
                children: [
                  _Dropdown(
                    label: 'Status',
                    value: _status!,
                    options: paymentStatuses,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  _Dropdown(
                    label: 'Mode',
                    value: _mode?.isEmpty ?? true ? 'RTGS' : _mode!,
                    options: paymentModes,
                    onChanged: (v) => setState(() => _mode = v),
                  ),
                  TextField(
                    controller: _txn,
                    decoration: const InputDecoration(
                        labelText: 'Transaction ID',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Paid Date',
                          value: _paidDate,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Due Date',
                          value: _dueDate,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.canDelete)
            OutlinedButton.icon(
              onPressed: _delete,
              style:
                  OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Payment'),
            ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label:  ',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            TextSpan(
              text: value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          isDense: true,
        ),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value == null ? 'Pick date' : Formatters.date(value)),
      ),
    );
  }
}