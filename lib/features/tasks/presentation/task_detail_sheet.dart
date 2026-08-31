// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_item.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_pill.dart';
import 'tasks_controller.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final TaskItem initial;
  final List<String> statuses;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onChanged;

  const TaskDetailSheet({
    super.key,
    required this.initial,
    this.statuses = const ['Pending', 'In Progress', 'Overdue', 'Completed'],
    required this.canEdit,
    required this.canDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  Future<void> _changeStatus() async {
    final v = await showFilterSheet(
      context,
      title: 'Update Task Status',
      options: [for (final s in widget.statuses) (s, s)],
      current: widget.initial.status,
    );
    if (v == null || v == widget.initial.status) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(tasksControllerProvider.notifier)
          .setStatus(widget.initial.id, v);
      widget.onChanged();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text('Task marked $v'),
            behavior: SnackBarBehavior.floating));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirm(
      context,
      title: 'Delete task?',
      content: '${widget.initial.title} (${widget.initial.taskId}) will be removed.',
      confirmLabel: 'Delete',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!ok) return;
    try {
      await ref
          .read(tasksControllerProvider.notifier)
          .deleteTask(widget.initial.id);
      widget.onChanged();
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, 'Task deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.initial;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.taskId,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text(t.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              StatusPill(label: t.status),
            ],
          ),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t.description!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Details',
            child: Column(
              children: [
                _row('Type', t.type),
                _row('Priority', t.priority),
                if (t.dueDate != null)
                  _row('Due', '${Formatters.date(t.dueDate)}'
                      '${t.dueTime != null ? ' ${t.dueTime}' : ''}'),
                if (t.assigneeName != null) _row('Assignee', t.assigneeName!),
                if (t.leadName != null) _row('Lead', t.leadName!),
                if (t.relatedTo != null) _row('Related to', t.relatedTo!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.canEdit)
            FilledButton.tonal(
              onPressed: _changeStatus,
              child: const Text('Update Status'),
            ),
          if (widget.canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                child: const Text('Delete'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: theme.textTheme.bodySmall),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}