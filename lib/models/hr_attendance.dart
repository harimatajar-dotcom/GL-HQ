class HrEmployee {
  final int staffId;
  final String name;
  final String role;
  final String roleLabel;
  final String? mobile;
  String status; // mutable — "present", "half_day", "full_day_leave"
  final bool isMarked;

  HrEmployee({
    required this.staffId,
    required this.name,
    required this.role,
    required this.roleLabel,
    this.mobile,
    this.status = 'present',
    this.isMarked = false,
  });

  factory HrEmployee.fromJson(Map<String, dynamic> json) => HrEmployee(
        staffId: json['staff_id'] is int
            ? json['staff_id']
            : int.tryParse(json['staff_id']?.toString() ?? '') ??
                (json['id'] is int
                    ? json['id']
                    : int.tryParse(json['id']?.toString() ?? '') ?? 0),
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        roleLabel: json['role_label']?.toString() ?? json['role']?.toString() ?? '',
        mobile: json['mobile']?.toString(),
        status: json['status']?.toString() ?? 'present',
        isMarked: json['is_marked'] == true || json['is_marked'] == 1,
      );

  bool get isPresent => status == 'present';
  bool get isHalfDay => status == 'half_day';
  bool get isFullDayLeave => status == 'full_day_leave';
}

class HrDailyReport {
  final int? id;
  final String reportDate;
  final int totalEmployees;
  final int presentCount;
  final int halfDayCount;
  final int fullDayLeaveCount;
  final int interviewsScheduled;
  final int interviewsCompleted;
  final String? hrNote;
  final String? submittedByName;
  final String? createdAt;

  HrDailyReport({
    this.id,
    required this.reportDate,
    this.totalEmployees = 0,
    this.presentCount = 0,
    this.halfDayCount = 0,
    this.fullDayLeaveCount = 0,
    this.interviewsScheduled = 0,
    this.interviewsCompleted = 0,
    this.hrNote,
    this.submittedByName,
    this.createdAt,
  });

  factory HrDailyReport.fromJson(Map<String, dynamic> json) => HrDailyReport(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
        reportDate: json['report_date']?.toString() ?? json['date']?.toString() ?? '',
        totalEmployees: _toInt(json['total_employees']),
        presentCount: _toInt(json['present_count'] ?? json['present']),
        halfDayCount: _toInt(json['half_day_count'] ?? json['half_day']),
        fullDayLeaveCount: _toInt(json['full_day_leave_count'] ?? json['full_day_leave']),
        interviewsScheduled: _toInt(json['interviews_scheduled']),
        interviewsCompleted: _toInt(json['interviews_completed']),
        hrNote: json['hr_note']?.toString(),
        submittedByName: json['submitted_by_name']?.toString(),
        createdAt: json['created_at']?.toString(),
      );

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}
