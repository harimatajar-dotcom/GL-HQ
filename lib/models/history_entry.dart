class HistoryEntry {
  final int id;
  final int taskId;
  final int staffId;
  final String action;
  final String? oldValue;
  final String? newValue;
  final String createdAt;
  final String? staffName;

  HistoryEntry({
    required this.id,
    required this.taskId,
    required this.staffId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.createdAt,
    this.staffName,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: int.parse(json['id'].toString()),
    taskId: int.parse(json['task_id'].toString()),
    staffId: int.parse(json['staff_id'].toString()),
    action: json['action'] ?? '',
    oldValue: json['old_value'],
    newValue: json['new_value'],
    createdAt: json['created_at'] ?? '',
    staffName: json['staff_name'],
  );

  String get description => switch (action) {
    'created' => '${staffName ?? 'Someone'} created this task',
    'status_changed' => '${staffName ?? 'Someone'} changed status from $oldValue to $newValue',
    'assigned' => '${staffName ?? 'Someone'} assigned to $newValue',
    'commented' => '${staffName ?? 'Someone'} added a comment',
    'updated' => '${staffName ?? 'Someone'} updated the task',
    'deleted' => '${staffName ?? 'Someone'} deleted the task',
    _ => '${staffName ?? 'Someone'} performed $action',
  };
}
