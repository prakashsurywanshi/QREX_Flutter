import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/form_fields.dart';
import 'payments_controller.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const PaymentFormSheet({super.key, required this.onSaved});

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _property = TextEditingController();
  final _amount = TextEditingController();
  String? _mode = 'RTGS';
  String? _status = 'Pending';
  bool _saving = false;

  @override
  void dispose() {
    _customer.dispose();
    _property.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(paymentsControllerProvider.notifier).createPayment({
        'customer_name': _customer.text.trim(),
        'property_name': _property.text.trim(),
        'amount': num.tryParse(_amount.text.trim())?.toDouble() ?? 0,
        'mode': _mode,
        'status': _status,
      });
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Payment recorded.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      if (mounted) navigator.pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Record Payment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Customer Name *',
              controller: _customer,
              icon: Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Customer name is required'
                  : null,
            ),
            AppTextField(
              label: 'Property Name *',
              controller: _property,
              icon: Icons.apartment,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Property name is required'
                  : null,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Amount (₹) *',
                  controller: _amount,
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (v) => num.tryParse((v ?? '').trim()) == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                AmountInWordsHint(controller: _amount),
              ],
            ),
            AppDropdownField<String>(
              label: 'Mode',
              value: _mode,
              options: [for (final m in paymentModes) (m, m)],
              onChanged: (v) => setState(() => _mode = v),
            ),
            AppDropdownField<String>(
              label: 'Status',
              value: _status,
              options: [
                for (final s in [
                  'Pending',
                  'Partially Paid',
                  'Paid',
                  'Overdue',
                ])
                  (s, s),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
