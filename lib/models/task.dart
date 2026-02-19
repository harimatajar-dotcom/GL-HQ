import '../config/constants.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final int? assignedTo;
  final int? createdBy;
  final String priority;
  final String status;
  final String? dueDate;
  final String? completedAt;
  final String? notes;
  final String? category;
  final String createdAt;
  final String updatedAt;
  final String? assigneeName;
  final String? assigneeRole;
  final String? creatorName;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.createdBy,
    this.priority = 'normal',
    this.status = 'pending',
    this.dueDate,
    this.completedAt,
    this.notes,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeName,
    this.assigneeRole,
    this.creatorName,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: int.parse(json['id'].toString()),
    title: json['title'] ?? '',
    description: json['description'],
    assignedTo: json['assigned_to'] != null ? int.tryParse(json['assigned_to'].toString()) : null,
    createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
    priority: json['priority'] ?? 'normal',
    status: json['status'] ?? 'pending',
    dueDate: json['due_date'],
    completedAt: json['completed_at'],
    notes: json['notes'],
    category: json['category'],
    createdAt: json['created_at'] ?? '',
    updatedAt: json['updated_at'] ?? '',
    assigneeName: json['assignee_name'],
    assigneeRole: json['assignee_role'],
    creatorName: json['creator_name'],
  );

  bool get isOverdue {
    if (dueDate == null || status == 'done') return false;
    return DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) ?? false;
  }

  String get categoryEmoji => AppConstants.categoryEmojis[category] ?? '📌';
}
