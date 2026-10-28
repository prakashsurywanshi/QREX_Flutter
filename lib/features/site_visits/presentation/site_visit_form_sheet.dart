// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/site_visit.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/form_fields.dart';
import 'site_visits_controller.dart';

class SiteVisitFormSheet extends ConsumerStatefulWidget {
  final SiteVisitItem? initial;
  final VoidCallback onSaved;

  const SiteVisitFormSheet({super.key, this.initial, required this.onSaved});

  @override
  ConsumerState<SiteVisitFormSheet> createState() => _SiteVisitFormSheetState();
}

class _SiteVisitFormSheetState extends ConsumerState<SiteVisitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customer;
  late final TextEditingController _property;
  late final TextEditingController _agent;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  String? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    _customer = TextEditingController(text: v?.customerName ?? '');
    _property = TextEditingController(text: v?.propertyName ?? '');
    _agent = TextEditingController(text: v?.agentName ?? '');
    _date = TextEditingController(
      text: v == null || v.visitDate.isEmpty
          ? ''
          : Formatters.date(v.visitDate),
    );
    _time = TextEditingController(text: v?.visitTime ?? '');
    _location = TextEditingController(text: v?.location ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');
    _status = v == null || v.status.isEmpty ? 'Scheduled' : v.status;
  }

  @override
  void dispose() {
    for (final c in [
      _customer,
      _property,
      _agent,
      _date,
      _time,
      _location,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) _date.text = Formatters.displayFromDateTime(d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
      _time.text = '$h:${t.minute.toString().padLeft(2, '0')} $suffix';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;

    final payload = <String, dynamic>{
      'customer_name': _customer.text.trim(),
      'property_name': _property.text.trim(),
      'agent_name': _agent.text.trim().isEmpty
          ? 'Unassigned'
          : _agent.text.trim(),
      'visit_date': Formatters.toIsoDate(_date.text.trim()),
      'visit_time': _time.text.trim().isEmpty ? '10:00 AM' : _time.text.trim(),
      if (_status != null) 'status': _status,
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(siteVisitsRepositoryProvider);
    try {
      if (isEdit) {
        await repo.update(widget.initial!.id, payload);
      } else {
        await repo.create(payload);
      }
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Site visit updated.' : 'Site visit scheduled.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              widget.initial == null ? 'Schedule Site Visit' : 'Edit Visit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(
                widget.initial!.visitId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Customer name *',
              controller: _customer,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Customer name is required'
                  : null,
            ),
            AppTextField(
              label: 'Property name *',
              controller: _property,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Property name is required'
                  : null,
            ),
            AppTextField(label: 'Agent name', controller: _agent),
            AppTextField(
              label: 'Visit date *',
              controller: _date,
              hint: 'DD/MM/YYYY',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Visit date is required'
                  : null,
              keyboardType: null,
            ),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Pick date'),
            ),
            AppTextField(
              label: 'Visit time *',
              controller: _time,
              hint: 'e.g. 10:00 AM',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Visit time is required'
                  : null,
            ),
            TextButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time, size: 16),
              label: const Text('Pick time'),
            ),
            AppDropdownField<String>(
              label: 'Status',
              value: _status,
              options: [for (final s in SiteVisitsController.statuses) (s, s)],
              onChanged: (v) => setState(() => _status = v),
            ),
            AppTextField(label: 'Location', controller: _location),
            AppTextField(label: 'Notes', controller: _notes, multiline: true),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
