class Comment {
  final int id;
  final int taskId;
  final int staffId;
  final String comment;
  final String createdAt;
  final String? staffName;
  final String? staffRole;

  Comment({
    required this.id,
    required this.taskId,
    required this.staffId,
    required this.comment,
    required this.createdAt,
    this.staffName,
    this.staffRole,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: int.parse(json['id'].toString()),
    taskId: int.parse(json['task_id'].toString()),
    staffId: int.parse(json['staff_id'].toString()),
    comment: json['comment'] ?? '',
    createdAt: json['created_at'] ?? '',
    staffName: json['staff_name'],
    staffRole: json['staff_role'],
  );
}
