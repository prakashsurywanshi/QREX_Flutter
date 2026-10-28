import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/form_fields.dart';
import 'bookings_controller.dart';

class BookingFormSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const BookingFormSheet({super.key, required this.onSaved});

  @override
  ConsumerState<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends ConsumerState<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _property = TextEditingController();
  final _agent = TextEditingController();
  final _date = TextEditingController();
  final _dealValue = TextEditingController();
  final _bookingAmount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _customer.dispose();
    _property.dispose();
    _agent.dispose();
    _date.dispose();
    _dealValue.dispose();
    _bookingAmount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) {
      _date.text = Formatters.displayFromDateTime(d);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(bookingsControllerProvider.notifier).createBooking({
        'customer_name': _customer.text.trim(),
        'property_name': _property.text.trim(),
        'agent_name': _agent.text.trim(),
        'booking_date': Formatters.toIsoDate(_date.text.trim()),
        'deal_value': num.tryParse(_dealValue.text.trim())?.toDouble() ?? 0,
        'booking_amount':
            num.tryParse(_bookingAmount.text.trim())?.toDouble() ?? 0,
      });
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Booking created.'),
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
      initialChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text('New Booking', style: Theme.of(context).textTheme.titleLarge),
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
            AppTextField(
              label: 'Agent Name *',
              controller: _agent,
              icon: Icons.badge_outlined,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Agent name is required'
                  : null,
            ),
            AppTextField(
              label: 'Booking Date *',
              controller: _date,
              icon: Icons.calendar_today,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Booking date is required'
                  : null,
              onTap: _pickDate,
              readOnly: true,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Deal Value (₹) *',
                  controller: _dealValue,
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (v) => num.tryParse((v ?? '').trim()) == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                AmountInWordsHint(controller: _dealValue),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Booking Amount (₹) *',
                  controller: _bookingAmount,
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (v) => num.tryParse((v ?? '').trim()) == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                AmountInWordsHint(controller: _bookingAmount),
              ],
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
                  : const Text('Create Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
