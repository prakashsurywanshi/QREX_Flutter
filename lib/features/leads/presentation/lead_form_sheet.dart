// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../widgets/form_fields.dart';
import 'leads_controller.dart';

class LeadFormSheet extends ConsumerStatefulWidget {
  final Lead? initial;
  final VoidCallback onSaved;
  final List<LeadOption> agents;

  const LeadFormSheet({
    super.key,
    this.initial,
    required this.onSaved,
    this.agents = const [],
  });

  @override
  ConsumerState<LeadFormSheet> createState() => _LeadFormSheetState();
}

class _LeadFormSheetState extends ConsumerState<LeadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _budget;
  late final TextEditingController _location;
  late final TextEditingController _requirements;
  late final TextEditingController _followup;
  String? _source;
  String? _status;
  int? _agentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    _name = TextEditingController(text: l?.name ?? '');
    _phone = TextEditingController(text: l?.phone ?? '');
    _email = TextEditingController(text: l?.email ?? '');
    _budget = TextEditingController(text: l?.budget ?? '');
    _location = TextEditingController(text: l?.preferredLocation ?? '');
    _requirements = TextEditingController(text: l?.requirements ?? '');
    _followup = TextEditingController(text: l?.nextFollowup ?? '');
    _source = l == null || l.source.isEmpty ? 'Website' : l.source;
    _status = l == null || l.status.isEmpty ? 'New' : l.status;
    _agentId = l?.agentId;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _email, _budget, _location, _requirements, _followup,
    ]) {
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
      'source': _source ?? 'Website',
      'status': _status ?? 'New',
      'budget': _budget.text.trim().isEmpty ? null : _budget.text.trim(),
      'preferred_location':
          _location.text.trim().isEmpty ? null : _location.text.trim(),
      'requirements':
          _requirements.text.trim().isEmpty ? null : _requirements.text.trim(),
      'next_followup': _followup.text.trim().isEmpty ? null : _followup.text.trim(),
      if (_agentId != null) 'assigned_agent_id': _agentId,
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(leadsRepositoryProvider);
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
          content: Text(isEdit ? 'Lead updated.' : 'Lead created.'),
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
    final lookups = ref
        .read(leadsControllerProvider.notifier)
        .lookups;
    final statuses = [
      if (lookups.statuses.isEmpty) 'New',
      ...lookups.statuses,
    ];
    final sources = [
      if (lookups.sources.isEmpty) 'Website',
      ...lookups.sources,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              widget.initial == null ? 'Add Lead' : 'Edit Lead',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(widget.initial!.leadId,
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Name *', controller: _name,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
            AppTextField(
                label: 'Phone *', controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null),
            AppTextField(
                label: 'Email', controller: _email,
                keyboardType: TextInputType.emailAddress),
            AppDropdownField<String>(
                label: 'Source *', value: _source,
                options: [for (final s in sources) (s, s)],
                onChanged: (v) => setState(() => _source = v)),
            AppDropdownField<String>(
                label: 'Status *', value: _status,
                options: [for (final s in statuses) (s, s)],
                onChanged: (v) => setState(() => _status = v)),
            AppTextField(
                label: 'Budget', controller: _budget,
                hint: 'e.g. 1.5 Cr'),
            AppTextField(
                label: 'Preferred location', controller: _location),
            AppTextField(
                label: 'Requirements', controller: _requirements,
                multiline: true),
            AppTextField(
                label: 'Next follow-up', controller: _followup,
                hint: 'e.g. 2026-09-05 10:00 AM'),
            if (widget.agents.isNotEmpty)
              AppDropdownField<int>(
                  label: 'Assigned agent', value: _agentId,
                  options: [for (final a in widget.agents) (a.id, a.name)],
                  onChanged: (v) => setState(() => _agentId = v)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
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