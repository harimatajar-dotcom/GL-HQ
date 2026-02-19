import '../config/constants.dart';

class Staff {
  final int id;
  final String name;
  final String role;
  final String? mobile;
  final String? telegramId;
  final bool active;
  final String? roleLabel;
  final int? activeTasks;
  final String? lastReportDate;
  final String? lastLogin;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    this.mobile,
    this.telegramId,
    this.active = true,
    this.roleLabel,
    this.activeTasks,
    this.lastReportDate,
    this.lastLogin,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    mobile: json['mobile'],
    telegramId: json['telegram_id'],
    active: json['active'] == 1 || json['active'] == true,
    roleLabel: json['role_label'],
    activeTasks: json['active_tasks'] != null ? int.tryParse(json['active_tasks'].toString()) : null,
    lastReportDate: json['last_report_date'],
    lastLogin: json['last_login'],
  );

  String get emoji => AppConstants.roleEmojis[role] ?? '👤';
  String get label => roleLabel ?? AppConstants.roleLabels[role] ?? role;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is Staff && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
