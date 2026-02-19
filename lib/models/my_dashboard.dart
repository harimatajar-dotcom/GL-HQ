class MyDashboard {
  final int tasksOpen;
  final int tasksCompletedMonth;
  final int tasksOverdue;
  final String completionRate;
  final int tasksCompletedWeek;
  final int reportStreak;
  final String? lastReportDate;
  final List<dynamic> reportCalendar;
  final String avgCompletionDays;
  final bool reportedToday;

  MyDashboard({
    required this.tasksOpen,
    required this.tasksCompletedMonth,
    required this.tasksOverdue,
    required this.completionRate,
    required this.tasksCompletedWeek,
    required this.reportStreak,
    this.lastReportDate,
    required this.reportCalendar,
    required this.avgCompletionDays,
    required this.reportedToday,
  });

  factory MyDashboard.fromJson(Map<String, dynamic> json) => MyDashboard(
    tasksOpen: int.tryParse(json['tasks_open'].toString()) ?? 0,
    tasksCompletedMonth: int.tryParse(json['tasks_completed_month'].toString()) ?? 0,
    tasksOverdue: int.tryParse(json['tasks_overdue'].toString()) ?? 0,
    completionRate: json['completion_rate']?.toString() ?? '0%',
    tasksCompletedWeek: int.tryParse(json['tasks_completed_week'].toString()) ?? 0,
    reportStreak: int.tryParse(json['report_streak'].toString()) ?? 0,
    lastReportDate: json['last_report_date'],
    reportCalendar: json['report_calendar'] ?? [],
    avgCompletionDays: json['avg_completion_days']?.toString() ?? '0',
    reportedToday: json['reported_today'] == true || json['reported_today'] == 1,
  );
}
