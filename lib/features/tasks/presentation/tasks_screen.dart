import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_item.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_sheet.dart';
import '../../../widgets/status_pill.dart';
import 'task_detail_sheet.dart';
import 'task_form_sheet.dart';
import 'tasks_controller.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(tasksControllerProvider.notifier);
      if (ref.read(tasksControllerProvider).tasks.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksControllerProvider);
    final controller = ref.read(tasksControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('tasks') == true;
    final canEdit = can?.canEdit('tasks') == true;
    final canDelete = can?.canDelete('tasks') == true;

    final statuses = state.statuses.isEmpty
        ? const ['All', 'Pending', 'In Progress', 'Overdue', 'Completed']
        : ['All', ...state.statuses];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_task),
              label: const Text('Task'),
            )
          : null,
      body: Column(
        children: [
          _SummaryStrip(summary: state.summary),
          const Divider(height: 1),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final s in statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: state.statusFilter == s,
                      onSelected: (_) => controller.filterStatus(s),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ActionChip(
                  label: Text(state.assigneeFilter == null
                      ? 'All agents'
                      : state.agents
                          .where((a) => a.id == state.assigneeFilter)
                          .map((a) => a.name)
                          .firstOrNull ??
                          'Agent'),
                  avatar: const Icon(Icons.person, size: 16),
                  onPressed: () async {
                    final opts = [
                      ('', 'All agents'),
                      for (final a in state.agents) ('${a.id}', a.name),
                    ];
                    final v = await showFilterSheet(context,
                        title: 'Filter by Agent',
                        options: opts,
                        current: state.assigneeFilter?.toString() ?? '');
                    if (v != null) {
                      controller.filterAssignee(v.isEmpty ? null : int.tryParse(v));
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: state.loading && state.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.tasks.isEmpty
                    ? EmptyState(
                        icon: Icons.task_alt,
                        message: 'No tasks found',
                        action: FilledButton(
                            onPressed: controller.load,
                            child: const Text('Retry')),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 96),
                          itemCount: state.filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final t = state.filtered[i];
                            return _TaskTile(
                              task: t,
                              canComplete: canEdit,
                              onComplete: () =>
                                  controller.setStatus(t.id, 'Completed'),
                              onTap: canEdit || canDelete
                                  ? () => _openDetail(context, t, canEdit,
                                      canDelete)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, TaskItem t,
      bool canEdit, bool canDelete) async {
    if (!(canEdit || canDelete)) return;
    final state = ref.read(tasksControllerProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => TaskDetailSheet(
        initial: t,
        statuses: state.statuses,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: () =>
            ref.read(tasksControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final state = ref.read(tasksControllerProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => TaskFormSheet(
        types: state.types,
        priorities: state.priorities,
        agents: state.agents,
        leads: state.leads,
        onSaved: () =>
            ref.read(tasksControllerProvider.notifier).load(),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final dynamic summary;
  const _SummaryStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cells = <(String, int, Color)>[
      ('Pending', summary.pending as int, Colors.orange.shade800),
      ('In Progress', summary.inProgress as int, Colors.blue.shade700),
      ('Due Today', summary.dueToday as int, Colors.indigo.shade600),
      ('Overdue', summary.overdue as int, Colors.red.shade700),
      ('Done', summary.completed as int, Colors.green.shade700),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: cells.map((c) {
          return Expanded(
            child: Column(
              children: [
                Text('${c.$2}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: c.$3)),
                Text(c.$1, style: theme.textTheme.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;
  final bool canComplete;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const _TaskTile({
    required this.task,
    this.canComplete = false,
    this.onComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.status == 'Overdue';
    final done = task.status == 'Completed';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (canComplete)
                Checkbox(
                  value: done,
                  onChanged: (v) => onComplete?.call(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration:
                                    done ? TextDecoration.lineThrough : null),
                          ),
                        ),
                        StatusPill(label: task.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        task.type,
                        if (task.dueDate != null)
                          'Due ${Formatters.date(task.dueDate)}'
                              '${task.dueTime != null ? ' ${task.dueTime}' : ''}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (task.assigneeName != null ||
                        task.leadName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (task.assigneeName != null)
                              'For: ${task.assigneeName}',
                            if (task.leadName != null)
                              'Lead: ${task.leadName}',
                          ].join(' · '),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}