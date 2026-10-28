// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/deal.dart';
import '../../../core/models/lead.dart';
import '../../../widgets/form_fields.dart';
import 'pipeline_controller.dart';

class PipelineFormSheet extends ConsumerStatefulWidget {
  final Deal? initial;
  final VoidCallback onSaved;
  final List<String> stages;
  final List<LeadOption> properties;
  final List<LeadOption> customers;
  final List<LeadOption> agents;

  const PipelineFormSheet({
    super.key,
    this.initial,
    required this.onSaved,
    this.stages = const [],
    this.properties = const [],
    this.customers = const [],
    this.agents = const [],
  });

  @override
  ConsumerState<PipelineFormSheet> createState() => _PipelineFormSheetState();
}

class _PipelineFormSheetState extends ConsumerState<PipelineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerName;
  late final TextEditingController _value;
  String? _stage;
  int? _probability;
  int? _propertyId;
  int? _agentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _customerName = TextEditingController(text: d?.customerName ?? '');
    _value = TextEditingController(
      text: d == null || d.dealValue == 0 ? '' : d.dealValue.toString(),
    );
    _stage = d?.stage.isEmpty == false ? d!.stage : (widget.stages.firstOrNull);
    _probability = d == null || d.probability == 0 ? null : d.probability;
    _propertyId = d?.propertyId;
    _agentId = d?.agentId;
  }

  @override
  void dispose() {
    _customerName.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;

    final payload = <String, dynamic>{
      'customer_name': _customerName.text.trim(),
      'deal_value': num.tryParse(_value.text.trim()) ?? 0,
      if (_stage != null) 'stage': _stage,
      if (_probability != null) 'probability': _probability,
      if (_propertyId != null) 'property_id': _propertyId,
      if (_agentId != null) 'assigned_agent_id': _agentId,
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(pipelineControllerProvider.notifier);
    try {
      if (isEdit) {
        await controller.updateDeal(widget.initial!.id, payload);
      } else {
        await controller.createDeal(payload);
      }
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Deal updated.' : 'Deal created.'),
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
    final stages = widget.stages.isEmpty
        ? const ['New Lead', 'Contacted', 'Qualified']
        : widget.stages;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
              widget.initial == null ? 'Add Deal' : 'Edit Deal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(
                widget.initial!.dealId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Customer name *',
              controller: _customerName,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Customer name is required'
                  : null,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Deal value (₹) *',
                  controller: _value,
                  keyboardType: TextInputType.number,
                  validator: (v) => num.tryParse((v ?? '').trim()) == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                AmountInWordsHint(controller: _value),
              ],
            ),
            if (widget.properties.isNotEmpty)
              AppDropdownField<int>(
                label: 'Property',
                value: _propertyId,
                options: [for (final p in widget.properties) (p.id, p.name)],
                onChanged: (v) => setState(() => _propertyId = v),
              ),
            AppDropdownField<String>(
              label: 'Stage',
              value: _stage,
              options: [for (final s in stages) (s, s)],
              onChanged: (v) => setState(() => _stage = v),
            ),
            AppDropdownField<int>(
              label: 'Probability',
              value: _probability,
              options: [
                for (final p in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
                  (p, '$p%'),
              ],
              onChanged: (v) => setState(() => _probability = v),
            ),
            if (widget.agents.isNotEmpty)
              AppDropdownField<int>(
                label: 'Assigned agent',
                value: _agentId,
                options: [for (final a in widget.agents) (a.id, a.name)],
                onChanged: (v) => setState(() => _agentId = v),
              ),
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
