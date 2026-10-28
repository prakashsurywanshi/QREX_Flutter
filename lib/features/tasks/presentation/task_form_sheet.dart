// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../core/models/task_item.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/form_fields.dart';
import 'tasks_controller.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  final TaskItem? initial;
  final VoidCallback onSaved;
  final List<String> types;
  final List<String> priorities;
  final List<LeadOption> agents;
  final List<LeadOption> leads;

  const TaskFormSheet({
    super.key,
    this.initial,
    required this.onSaved,
    this.types = const [],
    this.priorities = const [],
    this.agents = const [],
    this.leads = const [],
  });

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _dueDate;
  String? _type;
  String? _priority;
  String? _status;
  int? _assigneeId;
  int? _leadId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _dueDate = TextEditingController(
      text: t == null || t.dueDate == null || t.dueDate!.isEmpty
          ? ''
          : Formatters.date(t.dueDate),
    );
    _type = t == null || t.type.isEmpty ? null : t.type;
    _priority = t == null || t.priority.isEmpty ? 'Medium' : t.priority;
    _status = t?.status;
    _assigneeId = t?.assigneeId;
    _leadId = t?.leadId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) _dueDate.text = Formatters.displayFromDateTime(d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;

    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      if (_type != null) 'type': _type,
      if (_priority != null) 'priority': _priority,
      if (_status != null) 'status': _status,
      if (_dueDate.text.trim().isNotEmpty)
        'due_date': Formatters.toIsoDate(_dueDate.text.trim()),
      if (_assigneeId != null) 'assigned_to_id': _assigneeId,
      if (_leadId != null) 'lead_id': _leadId,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(tasksRepositoryProvider);
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
            content: Text(isEdit ? 'Task updated.' : 'Task created.'),
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
    final types = widget.types.isEmpty
        ? const ['Follow-up', 'Call', 'Meeting', 'Site Visit', 'Email', 'Other']
        : widget.types;
    final priorities = widget.priorities.isEmpty
        ? const ['Low', 'Medium', 'High', 'Urgent']
        : widget.priorities;

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
              widget.initial == null ? 'Add Task' : 'Edit Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(
                widget.initial!.taskId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Title *',
              controller: _title,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            AppDropdownField<String>(
              label: 'Type',
              value: _type,
              options: [for (final s in types) (s, s)],
              onChanged: (v) => setState(() => _type = v),
            ),
            AppDropdownField<String>(
              label: 'Priority',
              value: _priority,
              options: [for (final s in priorities) (s, s)],
              onChanged: (v) => setState(() => _priority = v),
            ),
            if (widget.initial != null)
              AppDropdownField<String>(
                label: 'Status',
                value: _status,
                options: const [
                  ('Pending', 'Pending'),
                  ('In Progress', 'In Progress'),
                  ('Overdue', 'Overdue'),
                  ('Completed', 'Completed'),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            AppTextField(
              label: 'Due date',
              controller: _dueDate,
              hint: 'DD/MM/YYYY',
            ),
            TextButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Pick due date'),
            ),
            if (widget.agents.isNotEmpty)
              AppDropdownField<int>(
                label: 'Assignee',
                value: _assigneeId,
                options: [for (final a in widget.agents) (a.id, a.name)],
                onChanged: (v) => setState(() => _assigneeId = v),
              ),
            if (widget.leads.isNotEmpty)
              AppDropdownField<int>(
                label: 'Lead',
                value: _leadId,
                options: [for (final l in widget.leads) (l.id, l.name)],
                onChanged: (v) => setState(() => _leadId = v),
              ),
            AppTextField(
              label: 'Description',
              controller: _description,
              multiline: true,
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
