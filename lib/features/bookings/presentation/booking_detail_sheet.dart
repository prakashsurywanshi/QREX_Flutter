// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/payment.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import '../../payments/presentation/payments_controller.dart';
import 'bookings_controller.dart';

class BookingDetailSheet extends ConsumerStatefulWidget {
  final Booking initial;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const BookingDetailSheet({
    super.key,
    required this.initial,
    this.canEdit = false,
    this.canDelete = false,
    required this.onChanged,
  });

  @override
  ConsumerState<BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<BookingDetailSheet> {
  BookingDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final d = await ref
          .read(bookingsRepositoryProvider)
          .show(widget.initial.id);
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateField(String key, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref
          .read(bookingsRepositoryProvider)
          .update(widget.initial.id, {key: value});
      widget.onChanged();
      await _reload();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Booking updated.'),
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

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController();
    String? mode = 'Bank Transfer';
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: mode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: [
                for (final m in paymentModes)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => mode = v,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final amount = num.tryParse(amountCtrl.text.trim())?.toDouble();
    if (amount == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Enter a valid amount.'),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    try {
      await ref.read(bookingsRepositoryProvider).update(widget.initial.id, {
        'record_payment': true,
        'payment_amount': amount,
        'payment_mode': mode,
      });
      widget.onChanged();
      await _reload();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Payment recorded.'),
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
        title: 'Delete Booking?',
        content:
            'Delete booking ${widget.initial.bookingId} for ${widget.initial.customerName}?',
        confirmLabel: 'Delete');
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(bookingsRepositoryProvider).delete(widget.initial.id);
      widget.onChanged();
      if (mounted) navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Booking deleted.'),
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
    final detail = _detail;
    final initial = detail?.booking ?? widget.initial;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => _loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Row(
                  children: [
                    InitialsAvatar(name: initial.customerName, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(initial.customerName,
                              style: theme.textTheme.titleLarge),
                          Text(initial.bookingId,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                    StatusPill(label: initial.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LabelValue(
                          label: 'Deal Value',
                          value: initial.dealLabel ??
                              Formatters.inrLabel(initial.dealValue)),
                    ),
                    Expanded(
                      child: _LabelValue(
                          label: 'Booking Amount',
                          value: initial.bookingAmountLabel ??
                              Formatters.inrLabel(initial.bookingAmount)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LabelValue(label: 'Property', value: initial.propertyName),
                _LabelValue(label: 'Agent', value: initial.agentName),
                _LabelValue(
                    label: 'Booking Date',
                    value: Formatters.date(initial.bookingDate)),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Progress',
                  child: Column(
                    children: [
                      _StepRow(
                        label: 'Booking',
                        status: initial.bookingId.isNotEmpty
                            ? _StepState.done
                            : _StepState.pending,
                        date: '${initial.bookingId} · ${Formatters.date(initial.bookingDate)}',
                      ),
                      _StepRow(
                        label: 'Agreement',
                        status: initial.agreementStatus.toLowerCase() == 'signed'
                            ? _StepState.done
                            : _StepState.pending,
                        date: initial.agreementStatus,
                      ),
                      _StepRow(
                        label: 'Possession',
                        status: initial.possessionStatus == 'Handed Over'
                            ? _StepState.done
                            : _StepState.pending,
                        date: initial.possessionStatus,
                      ),
                    ],
                  ),
                ),
                if (widget.canEdit) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Update Status',
                    child: Column(
                      children: [
                        _StatusDropdown(
                          label: 'Booking Status',
                          value: initial.status,
                          options: bookingStatuses,
                          onChanged: (v) => _updateField('status', v!),
                        ),
                        _StatusDropdown(
                          label: 'Agreement Status',
                          value: initial.agreementStatus,
                          options: agreementStatuses,
                          onChanged: (v) => _updateField('agreement_status', v!),
                        ),
                        _StatusDropdown(
                          label: 'Possession Status',
                          value: initial.possessionStatus,
                          options: possessionStatuses,
                          onChanged: (v) =>
                              _updateField('possession_status', v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _recordPayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Record Payment'),
                  ),
                ],
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Payments',
                  child: detail?.payments.isEmpty ?? true
                      ? Text('No payments recorded.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant))
                      : Column(
                          children: [
                            for (final p in detail!.payments)
                              _PaymentRow(payment: p),
                          ],
                        ),
                ),
                if (widget.canDelete) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Booking'),
                  ),
                ],
              ],
            ),
    );
  }
}

enum _StepState { pending, done }

class _StepRow extends StatelessWidget {
  final String label;
  final _StepState status;
  final String date;
  const _StepRow(
      {required this.label, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = status == _StepState.done;
    final color = done ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.circle_outlined,
              size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(date, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

class _StatusDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({
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

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.paymentId, style: theme.textTheme.labelMedium),
                Text('${payment.mode} · ${Formatters.date(payment.dueDate)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          StatusPill(label: payment.status),
          const SizedBox(width: 8),
          Text(payment.amountLabel ?? Formatters.inrLabel(payment.amount),
              style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}