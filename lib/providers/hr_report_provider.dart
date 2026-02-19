import 'package:flutter/foundation.dart';
import '../models/hr_attendance.dart';
import '../services/api_service.dart';

class HRReportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<HrEmployee> _employees = [];
  HrDailyReport? _existingReport;
  bool _loading = false;
  String? _error;

  List<HrEmployee> get employees => _employees;
  HrDailyReport? get existingReport => _existingReport;
  bool get loading => _loading;
  String? get error => _error;
  bool get alreadySubmitted => _existingReport != null;

  int get presentCount => _employees.where((e) => e.isPresent).length;
  int get halfDayCount => _employees.where((e) => e.isHalfDay).length;
  int get fullDayLeaveCount => _employees.where((e) => e.isFullDayLeave).length;
  int get totalCount => _employees.length;

  List<HrEmployee> get absentEmployees =>
      _employees.where((e) => !e.isPresent).toList();

  Future<void> loadAttendanceList(String date) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getHRAttendanceList(date);
      final empList = data['employees'] as List? ?? [];
      _employees = empList.map((e) => HrEmployee.fromJson(Map<String, dynamic>.from(e))).toList();

      // Check if HR report already submitted for this date
      final hrReport = data['hr_report'];
      if (hrReport != null && hrReport is Map<String, dynamic>) {
        _existingReport = HrDailyReport.fromJson(hrReport);
      } else {
        _existingReport = null;
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Optimistic mark — updates UI first, then calls API, reverts on failure
  Future<({bool ok, String? error})> markAbsent({
    required String date,
    required int staffId,
    required String status,
  }) async {
    // Save old status for rollback
    String? oldStatus;
    for (final emp in _employees) {
      if (emp.staffId == staffId) {
        oldStatus = emp.status;
        emp.status = status; // Optimistic update
        break;
      }
    }
    notifyListeners();

    try {
      final result = await _api.hrMarkAbsent(
        date: date,
        staffId: staffId,
        status: status,
      );
      if (result['ok'] == true || result['success'] == true) {
        return (ok: true, error: null);
      }
      // Revert on failure
      if (oldStatus != null) {
        for (final emp in _employees) {
          if (emp.staffId == staffId) {
            emp.status = oldStatus;
            break;
          }
        }
        notifyListeners();
      }
      return (ok: false, error: (result['error'] as String?) ?? 'Failed');
    } catch (e) {
      // Revert on error
      if (oldStatus != null) {
        for (final emp in _employees) {
          if (emp.staffId == staffId) {
            emp.status = oldStatus;
            break;
          }
        }
        notifyListeners();
      }
      return (ok: false, error: e.toString());
    }
  }

  Future<({bool ok, String? error})> submitHRReport({
    required String date,
    required int interviewsScheduled,
    required int interviewsCompleted,
    required String hrNote,
  }) async {
    try {
      final result = await _api.submitHRReport(
        date: date,
        interviewsScheduled: interviewsScheduled,
        interviewsCompleted: interviewsCompleted,
        hrNote: hrNote,
      );
      if (result['ok'] == true || result['success'] == true) {
        return (ok: true, error: null);
      }
      return (ok: false, error: (result['error'] as String?) ?? 'Submission failed');
    } catch (e) {
      return (ok: false, error: e.toString());
    }
  }
}
