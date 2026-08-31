// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer.dart';
import '../../../widgets/form_fields.dart';
import 'customers_controller.dart';

class CustomerFormSheet extends ConsumerStatefulWidget {
  final Customer? initial;
  final VoidCallback onSaved;

  const CustomerFormSheet({super.key, this.initial, required this.onSaved});

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _city;
  late final TextEditingController _requirements;
  String? _type;
  String? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _city = TextEditingController(text: c?.city ?? '');
    _requirements = TextEditingController(text: c?.requirements ?? '');
    _type = c == null || c.type == null || c.type!.isEmpty ? null : c.type;
    _status = c == null || c.status.isEmpty ? 'Prospect' : c.status;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _city, _requirements]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'type': _type,
      'status': _status ?? 'Prospect',
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      if (isEdit && _requirements.text.trim().isNotEmpty)
        'requirements': _requirements.text.trim(),
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(customersRepositoryProvider);
    try {
      if (isEdit) {
        await repo.update(widget.initial!.id, payload);
      } else {
        await repo.create(payload);
      }
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(isEdit ? 'Customer updated.' : 'Customer created.'),
          behavior: SnackBarBehavior.floating,
        ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      if (ref.read(customersControllerProvider.notifier).statuses.isEmpty)
        'Prospect',
      ...ref.read(customersControllerProvider.notifier).statuses,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              widget.initial == null ? 'Add Customer' : 'Edit Customer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(widget.initial!.customerId,
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Name *', controller: _name,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null),
            AppTextField(
                label: 'Phone *', controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Phone is required'
                    : null),
            AppTextField(label: 'Email', controller: _email,
                keyboardType: TextInputType.emailAddress),
            AppDropdownField<String>(
                label: 'Type',
                value: _type,
                options: const [
                  ('', '—'),
                  ('Buyer', 'Buyer'),
                  ('Investor', 'Investor'),
                  ('Renter', 'Renter'),
                  ('Owner', 'Owner'),
                ],
                onChanged: (v) => setState(() => _type = v)),
            AppDropdownField<String>(
                label: 'Status',
                value: _status,
                options: [for (final s in statuses) (s, s)],
                onChanged: (v) => setState(() => _status = v)),
            AppTextField(label: 'City', controller: _city),
            if (widget.initial != null)
              AppTextField(label: 'Requirements', controller: _requirements,
                  multiline: true),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}