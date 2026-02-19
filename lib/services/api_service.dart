import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/staff.dart';
import '../models/task.dart';
import '../models/comment.dart';
import '../models/history_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/my_dashboard.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  String? _mobileToken;
  void setToken(String? token) => _mobileToken = token;
  String? get token => _mobileToken;

  // ========== GET REQUESTS ==========

  Future<Map<String, dynamic>> _get(String action, [Map<String, String>? params]) async {
    final queryParams = {
      'action': action,
      'api_token': AppConstants.apiToken,
      ...?params,
    };
    final response = await _dio.get('', queryParameters: queryParams);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<List<Staff>> getStaff() async {
    final data = await _get('staff');
    return (data['staff'] as List? ?? []).map((e) => Staff.fromJson(e)).toList();
  }

  Future<({List<Task> tasks, int total, int pages})> getTasks({
    int? assignedTo,
    String? status,
    String? priority,
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (assignedTo != null) params['assigned_to'] = assignedTo.toString();
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _get('tasks', params);
    final tasks = (data['tasks'] as List? ?? []).map((e) => Task.fromJson(e)).toList();
    return (
      tasks: tasks,
      total: int.tryParse(data['total'].toString()) ?? 0,
      pages: int.tryParse(data['pages'].toString()) ?? 1,
    );
  }

  Future<({Task task, List<Comment> comments, List<HistoryEntry> history})> getTaskDetail(int taskId) async {
    final data = await _get('task_detail', {'task_id': taskId.toString()});
    return (
      task: Task.fromJson(data['task']),
      comments: (data['comments'] as List? ?? []).map((e) => Comment.fromJson(e)).toList(),
      history: (data['history'] as List? ?? []).map((e) => HistoryEntry.fromJson(e)).toList(),
    );
  }

  Future<DashboardStats> getDashboardStats() async {
    final data = await _get('dashboard_stats');
    return DashboardStats.fromJson(data);
  }

  Future<List<Staff>> getTeamList() async {
    final data = await _get('team_list');
    return (data['staff'] as List? ?? []).map((e) => Staff.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getSummary(String date) async {
    return await _get('summary', {'date': date});
  }

  Future<Map<String, dynamic>> getToday() async => await _get('today');

  Future<List<dynamic>> getMissing() async {
    final data = await _get('missing');
    return data['missing'] ?? data['staff'] ?? [];
  }

  // ========== POST REQUESTS ==========

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (_mobileToken != null) {
      body['mobile_token'] = _mobileToken;
    }
    final response = await _dio.post('', data: body);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> mobileLogin(String mobile, String pin) async {
    final response = await _dio.post('', data: {
      'action': 'mobile_login',
      'mobile': mobile,
      'pin': pin,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _dio.post('', data: {
      'action': 'mobile_verify',
      'token': token,
    });
    return response.data;
  }

  Future<void> mobileLogout(String token) async {
    await _dio.post('', data: {'action': 'mobile_logout', 'token': token});
  }

  Future<MyDashboard> getMyDashboard() async {
    final data = await _post({'action': 'mobile_my_dashboard', 'token': _mobileToken});
    return MyDashboard.fromJson(data);
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    required List<int> assignees,
    String priority = 'normal',
    String? dueDate,
    String? category,
  }) async {
    return await _post({
      'action': 'task_create',
      'title': title,
      'description': description ?? '',
      'assignees': assignees,
      'priority': priority,
      'due_date': dueDate,
      'category': category,
    });
  }

  Future<Map<String, dynamic>> updateTask(int taskId, Map<String, dynamic> updates) async {
    return await _post({
      'action': 'task_update',
      'task_id': taskId,
      ...updates,
    });
  }

  Future<Map<String, dynamic>> addComment(int taskId, String comment) async {
    return await _post({
      'action': 'task_comment',
      'task_id': taskId,
      'comment': comment,
    });
  }

  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    return await _post({'action': 'task_delete', 'task_id': taskId});
  }

  Future<Map<String, dynamic>> submitReport(String date, Map<String, dynamic> data) async {
    return await _post({
      'action': 'mobile_submit_report',
      'token': _mobileToken,
      'date': date,
      'data': data,
    });
  }

  Future<Map<String, dynamic>> addTeamMember(Map<String, dynamic> data) async {
    return await _post({...data, 'action': 'team_add'});
  }

  Future<Map<String, dynamic>> updateTeamMember(Map<String, dynamic> data) async {
    return await _post({...data, 'action': 'team_update'});
  }

  Future<Map<String, dynamic>> toggleTeamMember(int id) async {
    return await _post({'action': 'team_toggle', 'id': id});
  }

  Future<Map<String, dynamic>> deleteTeamMember(int id) async {
    return await _post({'action': 'team_delete', 'id': id});
  }

  Future<Map<String, dynamic>> updateSetting(String key, dynamic value) async {
    return await _post({'action': 'settings_update', 'key': key, 'value': value});
  }

  // ========== HR REPORT ==========

  Future<Map<String, dynamic>> getHRAttendanceList(String date) async {
    return await _post({
      'action': 'hr_attendance_list',
      'date': date,
    });
  }

  Future<Map<String, dynamic>> hrMarkAbsent({
    required String date,
    int? staffId,
    String? status,
    List<Map<String, dynamic>>? entries,
  }) async {
    final body = <String, dynamic>{
      'action': 'hr_mark_absent',
      'date': date,
    };
    if (entries != null) {
      body['entries'] = entries;
    } else if (staffId != null) {
      body['staff_id'] = staffId;
      body['status'] = status ?? 'present';
    }
    return await _post(body);
  }

  Future<Map<String, dynamic>> submitHRReport({
    required String date,
    required int interviewsScheduled,
    required int interviewsCompleted,
    required String hrNote,
  }) async {
    return await _post({
      'action': 'hr_submit_report',
      'date': date,
      'interviews_scheduled': interviewsScheduled,
      'interviews_completed': interviewsCompleted,
      'hr_note': hrNote,
    });
  }

  Future<Map<String, dynamic>> getHRReports(String from, String to) async {
    return await _get('hr_reports', {'from': from, 'to': to});
  }

  Future<Map<String, dynamic>> getHRReportDetail(String date) async {
    return await _get('hr_report_detail', {'date': date});
  }
}
