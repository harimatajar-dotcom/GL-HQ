import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AnalyticsData {
  // Task Analytics
  final int totalCreated;
  final int totalCompleted;
  final int completionRate;
  final double avgCompletionDays;
  final int overdueCount;
  final List<ByPersonData> byPerson;
  final List<ByCategoryData> byCategory;
  final List<TrendData> trend;

  // Report Analytics
  final List<ReportPersonData> reportsByPerson;
  final List<StreakData> streaks;
  final List<ReportTrendData> reportTrend;

  // Team Performance
  final List<TeamMemberData> teamMembers;

  // HR Analytics
  final HRData? hrData;

  // Marketing
  final MarketingData? marketing;

  AnalyticsData({
    this.totalCreated = 0,
    this.totalCompleted = 0,
    this.completionRate = 0,
    this.avgCompletionDays = 0,
    this.overdueCount = 0,
    this.byPerson = const [],
    this.byCategory = const [],
    this.trend = const [],
    this.reportsByPerson = const [],
    this.streaks = const [],
    this.reportTrend = const [],
    this.teamMembers = const [],
    this.hrData,
    this.marketing,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
    totalCreated: int.tryParse(json['total_created']?.toString() ?? '0') ?? 0,
    totalCompleted: int.tryParse(json['total_completed']?.toString() ?? '0') ?? 0,
    completionRate: int.tryParse(json['completion_rate']?.toString() ?? '0') ?? 0,
    avgCompletionDays: double.tryParse(json['avg_completion_days']?.toString() ?? '0') ?? 0,
    overdueCount: int.tryParse(json['overdue_count']?.toString() ?? '0') ?? 0,
    byPerson: (json['by_person'] as List? ?? []).map((e) => ByPersonData.fromJson(e)).toList(),
    byCategory: (json['by_category'] as List? ?? []).map((e) => ByCategoryData.fromJson(e)).toList(),
    trend: (json['trend'] as List? ?? []).map((e) => TrendData.fromJson(e)).toList(),
    reportsByPerson: (json['reports_by_person'] as List? ?? []).map((e) => ReportPersonData.fromJson(e)).toList(),
    streaks: (json['streaks'] as List? ?? []).map((e) => StreakData.fromJson(e)).toList(),
    reportTrend: (json['report_trend'] as List? ?? []).map((e) => ReportTrendData.fromJson(e)).toList(),
    teamMembers: (json['members'] as List? ?? []).map((e) => TeamMemberData.fromJson(e)).toList(),
    hrData: json['attendance'] != null ? HRData.fromJson(json) : null,
    marketing: json['summary'] != null ? MarketingData.fromJson(json) : null,
  );
}

class ByPersonData {
  final String name;
  final int total;
  final int completed;
  final int rate;

  ByPersonData({
    required this.name,
    required this.total,
    required this.completed,
    required this.rate,
  });

  factory ByPersonData.fromJson(Map<String, dynamic> json) => ByPersonData(
    name: json['name'] ?? '',
    total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
    rate: int.tryParse(json['rate']?.toString() ?? '0') ?? 0,
  );
}

class ByCategoryData {
  final String category;
  final int count;

  ByCategoryData({
    required this.category,
    required this.count,
  });

  factory ByCategoryData.fromJson(Map<String, dynamic> json) => ByCategoryData(
    category: json['category'] ?? 'other',
    count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
  );
}

class TrendData {
  final String date;
  final int created;
  final int completed;

  TrendData({
    required this.date,
    required this.created,
    required this.completed,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) => TrendData(
    date: json['date'] ?? '',
    created: int.tryParse(json['created']?.toString() ?? '0') ?? 0,
    completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
  );

  String get dayLabel {
    final parts = date.split('-');
    if (parts.length >= 3) {
      return '${parts[1]}-${parts[2]}';
    }
    return date;
  }
}

class ReportPersonData {
  final String name;
  final int submitted;
  final int totalDays;
  final int rate;

  ReportPersonData({
    required this.name,
    required this.submitted,
    required this.totalDays,
    required this.rate,
  });

  factory ReportPersonData.fromJson(Map<String, dynamic> json) => ReportPersonData(
    name: json['name'] ?? '',
    submitted: int.tryParse(json['submitted']?.toString() ?? '0') ?? 0,
    totalDays: int.tryParse(json['total_days']?.toString() ?? '0') ?? 0,
    rate: int.tryParse(json['rate']?.toString() ?? '0') ?? 0,
  );
}

class StreakData {
  final String name;
  final int streak;

  StreakData({
    required this.name,
    required this.streak,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
    name: json['name'] ?? '',
    streak: int.tryParse(json['streak']?.toString() ?? '0') ?? 0,
  );
}

class ReportTrendData {
  final String date;
  final int submitted;

  ReportTrendData({
    required this.date,
    required this.submitted,
  });

  factory ReportTrendData.fromJson(Map<String, dynamic> json) => ReportTrendData(
    date: json['date'] ?? '',
    submitted: int.tryParse(json['submitted']?.toString() ?? '0') ?? 0,
  );

  String get dayLabel {
    final parts = date.split('-');
    if (parts.length >= 3) {
      return '${parts[1]}-${parts[2]}';
    }
    return date;
  }
}

class TeamMemberData {
  final int id;
  final String name;
  final String role;
  final String roleLabel;
  final String initials;
  final int tasksCompleted;
  final int tasksPending;
  final int overdue;
  final int reportsSubmitted;
  final int productivityScore;

  TeamMemberData({
    required this.id,
    required this.name,
    required this.role,
    required this.roleLabel,
    required this.initials,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.overdue,
    required this.reportsSubmitted,
    required this.productivityScore,
  });

  factory TeamMemberData.fromJson(Map<String, dynamic> json) => TeamMemberData(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    roleLabel: json['role_label'] ?? '',
    initials: json['initials'] ?? '',
    tasksCompleted: int.tryParse(json['tasks_completed']?.toString() ?? '0') ?? 0,
    tasksPending: int.tryParse(json['tasks_pending']?.toString() ?? '0') ?? 0,
    overdue: int.tryParse(json['overdue']?.toString() ?? '0') ?? 0,
    reportsSubmitted: int.tryParse(json['reports_submitted']?.toString() ?? '0') ?? 0,
    productivityScore: int.tryParse(json['productivity_score']?.toString() ?? '0') ?? 0,
  );
}

class HRData {
  final int presentDays;
  final int halfDays;
  final int leaveDays;
  final int attendanceRate;
  final List<LeaveByPersonData> leaveByPerson;

  HRData({
    required this.presentDays,
    required this.halfDays,
    required this.leaveDays,
    required this.attendanceRate,
    required this.leaveByPerson,
  });

  factory HRData.fromJson(Map<String, dynamic> json) => HRData(
    presentDays: int.tryParse(json['attendance']?['present_days']?.toString() ?? '0') ?? 0,
    halfDays: int.tryParse(json['attendance']?['half_days']?.toString() ?? '0') ?? 0,
    leaveDays: int.tryParse(json['attendance']?['leave_days']?.toString() ?? '0') ?? 0,
    attendanceRate: int.tryParse(json['attendance']?['attendance_rate']?.toString() ?? '0') ?? 0,
    leaveByPerson: (json['leave_by_person'] as List? ?? []).map((e) => LeaveByPersonData.fromJson(e)).toList(),
  );
}

class LeaveByPersonData {
  final String name;
  final int totalLeaves;

  LeaveByPersonData({
    required this.name,
    required this.totalLeaves,
  });

  factory LeaveByPersonData.fromJson(Map<String, dynamic> json) => LeaveByPersonData(
    name: json['name'] ?? '',
    totalLeaves: int.tryParse(json['total_leaves']?.toString() ?? '0') ?? 0,
  );
}

class MarketingData {
  final int totalRevenue;
  final int totalRegistrations;
  final int conversionRate;
  final int activeLeads;
  final List<FunnelStageData> funnel;
  final List<CampaignData> campaigns;

  MarketingData({
    required this.totalRevenue,
    required this.totalRegistrations,
    required this.conversionRate,
    required this.activeLeads,
    required this.funnel,
    required this.campaigns,
  });

  factory MarketingData.fromJson(Map<String, dynamic> json) => MarketingData(
    totalRevenue: int.tryParse(json['summary']?['total_revenue']?.toString() ?? '0') ?? 0,
    totalRegistrations: int.tryParse(json['summary']?['total_registrations']?.toString() ?? '0') ?? 0,
    conversionRate: int.tryParse(json['summary']?['conversion_rate']?.toString() ?? '0') ?? 0,
    activeLeads: int.tryParse(json['summary']?['active_leads']?.toString() ?? '0') ?? 0,
    funnel: (json['funnel'] as List? ?? []).map((e) => FunnelStageData.fromJson(e)).toList(),
    campaigns: (json['campaigns'] as List? ?? []).map((e) => CampaignData.fromJson(e)).toList(),
  );
}

class FunnelStageData {
  final String stage;
  final int count;

  FunnelStageData({
    required this.stage,
    required this.count,
  });

  factory FunnelStageData.fromJson(Map<String, dynamic> json) => FunnelStageData(
    stage: json['stage'] ?? '',
    count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
  );
}

class CampaignData {
  final String name;
  final int leads;

  CampaignData({
    required this.name,
    required this.leads,
  });

  factory CampaignData.fromJson(Map<String, dynamic> json) => CampaignData(
    name: json['name'] ?? json['campaign_name'] ?? 'Unknown',
    leads: int.tryParse((json['leads'] ?? json['lead_count'] ?? 0).toString()) ?? 0,
  );
}

class AnalyticsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AnalyticsData? _taskAnalytics;
  AnalyticsData? _reportAnalytics;
  AnalyticsData? _teamAnalytics;
  AnalyticsData? _hrAnalytics;
  AnalyticsData? _marketingAnalytics;

  bool _loading = false;
  String? _error;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  AnalyticsData? get taskAnalytics => _taskAnalytics;
  AnalyticsData? get reportAnalytics => _reportAnalytics;
  AnalyticsData? get teamAnalytics => _teamAnalytics;
  AnalyticsData? get hrAnalytics => _hrAnalytics;
  AnalyticsData? get marketingAnalytics => _marketingAnalytics;
  bool get loading => _loading;
  String? get error => _error;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
    loadAllAnalytics();
  }

  String get _fromStr => '${_fromDate.year}-${_fromDate.month.toString().padLeft(2, '0')}-${_fromDate.day.toString().padLeft(2, '0')}';
  String get _toStr => '${_toDate.year}-${_toDate.month.toString().padLeft(2, '0')}-${_toDate.day.toString().padLeft(2, '0')}';

  Future<void> loadTaskAnalytics() async {
    try {
      final data = await _api.analyticsTasks(_fromStr, _toStr);
      if (data['ok'] == true) {
        _taskAnalytics = AnalyticsData.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadReportAnalytics() async {
    try {
      final data = await _api.analyticsReports(_fromStr, _toStr);
      if (data['ok'] == true) {
        _reportAnalytics = AnalyticsData.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadTeamAnalytics() async {
    try {
      final data = await _api.analyticsTeam(_fromStr, _toStr);
      if (data['ok'] == true) {
        _teamAnalytics = AnalyticsData.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadHRAnalytics() async {
    try {
      final data = await _api.analyticsHR(_fromStr, _toStr);
      if (data['ok'] == true) {
        _hrAnalytics = AnalyticsData.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadMarketingAnalytics() async {
    try {
      final data = await _api.analyticsMarketing();
      if (data['ok'] == true) {
        _marketingAnalytics = AnalyticsData.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadAllAnalytics() async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.wait([
      loadTaskAnalytics(),
      loadReportAnalytics(),
      loadTeamAnalytics(),
      loadHRAnalytics(),
      loadMarketingAnalytics(),
    ]);

    _loading = false;
    notifyListeners();
  }
}
