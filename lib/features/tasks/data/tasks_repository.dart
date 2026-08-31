import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_helper.dart';
import '../../../core/models/lead.dart';
import '../../../core/models/task_item.dart';

class TaskSummary {
  final int total;
  final int pending;
  final int inProgress;
  final int dueToday;
  final int overdue;
  final int completed;

  const TaskSummary({
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.dueToday = 0,
    this.overdue = 0,
    this.completed = 0,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) => TaskSummary(
        total: json['total'] ?? 0,
        pending: json['pending'] ?? 0,
        inProgress: json['inProgress'] ?? 0,
        dueToday: json['dueToday'] ?? 0,
        overdue: json['overdue'] ?? 0,
        completed: json['completed'] ?? 0,
      );
}

class TaskIndex {
  final List<TaskItem> tasks;
  final List<LeadOption> agents;
  final List<LeadOption> leads;
  final List<String> statuses;
  final List<String> types;
  final List<String> priorities;
  final TaskSummary summary;

  const TaskIndex({
    this.tasks = const [],
    this.agents = const [],
    this.leads = const [],
    this.statuses = const [],
    this.types = const [],
    this.priorities = const [],
    this.summary = const TaskSummary(),
  });

  factory TaskIndex.fromJson(Map<String, dynamic> json) {
    List<LeadOption> options(String key) => (json[key] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => LeadOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return TaskIndex(
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      agents: options('agents'),
      leads: options('leads'),
      statuses: (json['statuses'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      types: (json['types'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      priorities: (json['priorities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      summary: TaskSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TasksRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<TaskIndex> fetch({
    String? status,
    int? assignee,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (status != null && status.isNotEmpty && status != 'All')
        'status': status,
      if (assignee != null) 'assignee': assignee,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    try {
      final res = await _dio.get(ApiEndpoints.tasks, queryParameters: query);
      return TaskIndex.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to load tasks.');
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiEndpoints.tasks, data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to create task.');
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiEndpoints.task(id), data: payload);
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to update task.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.task(id));
    } catch (e) {
      throw ApiHelper.toException(e, 'Unable to delete task.');
    }
  }
}