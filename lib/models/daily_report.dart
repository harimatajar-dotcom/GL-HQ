class DailyReport {
  final int? id;
  final int staffId;
  final String reportDate;
  final Map<String, dynamic> reportData;
  final String? submittedAt;
  final String? updatedAt;
  final String? staffName;
  final String? staffRole;

  DailyReport({
    this.id,
    required this.staffId,
    required this.reportDate,
    required this.reportData,
    this.submittedAt,
    this.updatedAt,
    this.staffName,
    this.staffRole,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        staffId: int.tryParse(json['staff_id'].toString()) ?? 0,
        reportDate: json['report_date'] ?? '',
        reportData: json['report_data'] is Map<String, dynamic>
            ? json['report_data']
            : {},
        submittedAt: json['submitted_at'],
        updatedAt: json['updated_at'],
        staffName: json['staff_name'],
        staffRole: json['staff_role'],
      );

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'date': reportDate,
        'data': reportData,
      };
}
