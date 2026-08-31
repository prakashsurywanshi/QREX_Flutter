import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lead.dart';
import '../../../core/models/task_item.dart';
import '../data/tasks_repository.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

class TasksState {
  final List<TaskItem> tasks;
  final List<LeadOption> agents;
  final List<LeadOption> leads;
  final List<String> statuses;
  final List<String> types;
  final List<String> priorities;
  final TaskSummary summary;
  final String statusFilter;
  final int? assigneeFilter;
  final bool loading;
  final String? error;

  const TasksState({
    this.tasks = const [],
    this.agents = const [],
    this.leads = const [],
    this.statuses = const [],
    this.types = const [],
    this.priorities = const [],
    this.summary = const TaskSummary(),
    this.statusFilter = 'All',
    this.assigneeFilter,
    this.loading = false,
    this.error,
  });

  List<TaskItem> get filtered {
    final s = statusFilter == 'All' ? null : statusFilter;
    final a = assigneeFilter;
    return tasks.where((t) {
      if (s != null && t.status != s) return false;
      if (a != null && t.assigneeId != a) return false;
      return true;
    }).toList();
  }

  TasksState copyWith({
    List<TaskItem>? tasks,
    List<LeadOption>? agents,
    List<LeadOption>? leads,
    List<String>? statuses,
    List<String>? types,
    List<String>? priorities,
    TaskSummary? summary,
    String? statusFilter,
    int? assigneeFilter,
    bool clearAssignee = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      agents: agents ?? this.agents,
      leads: leads ?? this.leads,
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      priorities: priorities ?? this.priorities,
      summary: summary ?? this.summary,
      statusFilter: statusFilter ?? this.statusFilter,
      assigneeFilter:
          clearAssignee ? null : (assigneeFilter ?? this.assigneeFilter),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TasksController extends StateNotifier<TasksState> {
  final TasksRepository _repo;

  TasksController(this._repo) : super(const TasksState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch(
        status: state.statusFilter == 'All' ? null : state.statusFilter,
        assignee: state.assigneeFilter,
      );
      state = state.copyWith(
        tasks: idx.tasks,
        agents: idx.agents,
        leads: idx.leads,
        statuses: idx.statuses,
        types: idx.types,
        priorities: idx.priorities,
        summary: idx.summary,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void filterStatus(String status) {
    state = state.copyWith(statusFilter: status);
    load();
  }

  void filterAssignee(int? assignee) {
    state = state.copyWith(assigneeFilter: assignee, clearAssignee: assignee == null);
    load();
  }

  Future<void> createTask(Map<String, dynamic> payload) async {
    await _repo.create(payload);
    await load();
  }

  Future<void> setStatus(int id, String status) async {
    await _repo.update(id, {'status': status});
    await load();
  }

  Future<void> deleteTask(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final tasksControllerProvider =
    StateNotifierProvider<TasksController, TasksState>((ref) {
  return TasksController(ref.watch(tasksRepositoryProvider));
});