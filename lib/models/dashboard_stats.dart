class DashboardStats {
  final int totalStaff;
  final int totalTasks;
  final int overdueTasks;
  final int completedToday;
  final int reportsSubmitted;
  final String reportRate;
  final String weekCompletion;
  final List<dynamic> recentActivity;
  final List<dynamic> teamStatus;
  final List<dynamic> reportsMissing;
  final List<dynamic> reportsSubmittedList;

  DashboardStats({
    required this.totalStaff,
    required this.totalTasks,
    required this.overdueTasks,
    required this.completedToday,
    required this.reportsSubmitted,
    required this.reportRate,
    required this.weekCompletion,
    required this.recentActivity,
    required this.teamStatus,
    required this.reportsMissing,
    required this.reportsSubmittedList,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalStaff: int.tryParse(json['total_staff'].toString()) ?? 0,
    totalTasks: int.tryParse(json['total_tasks'].toString()) ?? 0,
    overdueTasks: int.tryParse(json['overdue_tasks'].toString()) ?? 0,
    completedToday: int.tryParse(json['completed_today'].toString()) ?? 0,
    reportsSubmitted: int.tryParse(json['reports_submitted'].toString()) ?? 0,
    reportRate: json['report_rate']?.toString() ?? '0%',
    weekCompletion: json['week_completion']?.toString() ?? '0%',
    recentActivity: json['recent_activity'] ?? [],
    teamStatus: json['team_status'] ?? [],
    reportsMissing: json['reports_missing'] ?? [],
    reportsSubmittedList: json['reports_submitted_list'] ?? [],
  );
}
