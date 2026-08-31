import '../utils/num_parsers.dart';

class TaskItem {
  final int id;
  final String taskId;
  final String title;
  final String? description;
  final String type;
  final String status;
  final String priority;
  final String? dueDate;
  final String? dueTime;
  final String? relatedTo;
  final int? relatedId;
  final int? leadId;
  final int? assigneeId;
  final String? assigneeName;
  final String? leadName;

  const TaskItem({
    required this.id,
    this.taskId = '',
    this.title = '',
    this.description,
    this.type = 'Task',
    this.status = 'Pending',
    this.priority = 'Medium',
    this.dueDate,
    this.dueTime,
    this.relatedTo,
    this.relatedId,
    this.leadId,
    this.assigneeId,
    this.assigneeName,
    this.leadName,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    return TaskItem(
      id: json['id'],
      taskId: json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'Task',
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['due_date'],
      dueTime: json['due_time'],
      relatedTo: json['related_to'],
      relatedId: json['related_id'],
      leadId: json['lead_id'],
      assigneeId: (assignee is Map) ? parseInt(assignee['id']) : null,
      assigneeName: (assignee is Map) ? assignee['name']?.toString() : null,
      leadName: json['lead_name'],
    );
  }
}