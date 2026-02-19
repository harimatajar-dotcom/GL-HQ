import 'package:flutter/material.dart';
import '../config/constants.dart';

class Project {
  final int id;
  final String name;
  final String? description;
  final String status;
  final int? projectLead;
  final String? leadName;
  final int? createdBy;
  final String? creatorName;
  final String? startDate;
  final String? targetDate;
  final String createdAt;
  final String updatedAt;
  final int totalTasks;
  final int doneTasks;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.status = 'active',
    this.projectLead,
    this.leadName,
    this.createdBy,
    this.creatorName,
    this.startDate,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.totalTasks = 0,
    this.doneTasks = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: int.parse(json['id'].toString()),
    name: json['name'] ?? '',
    description: json['description'],
    status: json['status'] ?? 'active',
    projectLead: json['project_lead'] != null ? int.tryParse(json['project_lead'].toString()) : null,
    leadName: json['lead_name'],
    createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
    creatorName: json['creator_name'],
    startDate: json['start_date'],
    targetDate: json['target_date'],
    createdAt: json['created_at'] ?? '',
    updatedAt: json['updated_at'] ?? '',
    totalTasks: int.tryParse(json['total_tasks']?.toString() ?? '0') ?? 0,
    doneTasks: int.tryParse(json['done_tasks']?.toString() ?? '0') ?? 0,
  );

  int get progressPercent => totalTasks > 0 ? ((doneTasks / totalTasks) * 100).round() : 0;

  bool get isOverdue {
    if (targetDate == null || status == 'completed') return false;
    return DateTime.tryParse(targetDate!)?.isBefore(DateTime.now()) ?? false;
  }

  bool get isActive => status == 'active';
  bool get isOnHold => status == 'on_hold';
  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';

  Color get statusColor => switch (status) {
    'active' => AppColors.teal,
    'on_hold' => AppColors.amber,
    'completed' => AppColors.green,
    'archived' => AppColors.slate,
    _ => AppColors.slate,
  };

  Color get statusBgColor => switch (status) {
    'active' => const Color(0xFFCCFBF1),
    'on_hold' => const Color(0xFFFEF3C7),
    'completed' => const Color(0xFFD1FAE5),
    'archived' => const Color(0xFFF1F5F9),
    _ => AppColors.muted,
  };

  String get statusLabel => switch (status) {
    'active' => 'Active',
    'on_hold' => 'On Hold',
    'completed' => 'Completed',
    'archived' => 'Archived',
    _ => 'Unknown',
  };
}

class ProjectDetail {
  final Project project;
  final List<ProjectTask> tasks;

  ProjectDetail({
    required this.project,
    required this.tasks,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) => ProjectDetail(
    project: Project.fromJson(json['project']),
    tasks: (json['tasks'] as List? ?? []).map((e) => ProjectTask.fromJson(e)).toList(),
  );

  int get pendingTasks => tasks.where((t) => t.status == 'pending').length;
  int get inProgressTasks => tasks.where((t) => t.status == 'in_progress').length;
  int get doneTasks => tasks.where((t) => t.status == 'done').length;
  int get blockedTasks => tasks.where((t) => t.status == 'blocked').length;
}

class ProjectTask {
  final int id;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assigneeName;
  final String priority;
  final String status;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;

  ProjectTask({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.assigneeName,
    this.priority = 'normal',
    this.status = 'pending',
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: int.parse(json['id'].toString()),
    title: json['title'] ?? '',
    description: json['description'],
    assignedTo: json['assigned_to'] != null ? int.tryParse(json['assigned_to'].toString()) : null,
    assigneeName: json['assignee_name'],
    priority: json['priority'] ?? 'normal',
    status: json['status'] ?? 'pending',
    dueDate: json['due_date'],
    createdAt: json['created_at'] ?? '',
    updatedAt: json['updated_at'] ?? '',
  );

  bool get isOverdue {
    if (dueDate == null || status == 'done') return false;
    return DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) ?? false;
  }

  Color get priorityColor => AppColors.priorityColor(priority);
}

class ProjectActivity {
  final int id;
  final int taskId;
  final int staffId;
  final String staffName;
  final String action;
  final String? oldValue;
  final String? newValue;
  final String createdAt;
  final String taskTitle;
  final String? projectName;

  ProjectActivity({
    required this.id,
    required this.taskId,
    required this.staffId,
    required this.staffName,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.createdAt,
    required this.taskTitle,
    this.projectName,
  });

  factory ProjectActivity.fromJson(Map<String, dynamic> json) => ProjectActivity(
    id: int.parse(json['id'].toString()),
    taskId: int.parse(json['task_id'].toString()),
    staffId: int.parse(json['staff_id'].toString()),
    staffName: json['staff_name'] ?? '',
    action: json['action'] ?? '',
    oldValue: json['old_value'],
    newValue: json['new_value'],
    createdAt: json['created_at'] ?? '',
    taskTitle: json['task_title'] ?? '',
    projectName: json['project_name'],
  );

  String get actionLabel => switch (action) {
    'created' => 'created',
    'status_changed' => 'changed status',
    'commented' => 'commented on',
    'assigned' => 'reassigned',
    'updated' => 'updated',
    _ => action,
  };

  String get actionIcon => switch (action) {
    'created' => '✚',
    'status_changed' => '↻',
    'commented' => '💬',
    'assigned' => '👤',
    'updated' => '✎',
    _ => '•',
  };
}
