import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/staff.dart';
import '../models/task.dart';
import '../models/comment.dart';
import '../models/history_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/my_dashboard.dart';
import '../models/asset.dart';
import '../models/project.dart';

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

  // ========== ASSETS ==========

  Future<({List<Asset> assets, int total})> getAssets({
    String? search,
    String? status,
    String? category,
    int? assignedTo,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'action': 'assets_list',
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (category != null) params['type'] = category;
    if (assignedTo != null) params['assigned_to'] = assignedTo.toString();

    final data = await _get('assets', params);
    final assets = (data['assets'] as List? ?? []).map((e) => Asset.fromJson(e)).toList();
    return (
      assets: assets,
      total: int.tryParse(data['total'].toString()) ?? assets.length,
    );
  }

  Future<({Asset? asset, List<AssetAssignment> assignments, List<AssetRepair> repairs})> getAssetDetail(int assetId) async {
    final data = await _get('asset_detail', {'id': assetId.toString()});
    return (
      asset: data['asset'] != null ? Asset.fromJson(data['asset']) : null,
      assignments: (data['assignments'] as List? ?? []).map((e) => AssetAssignment.fromJson(e)).toList(),
      repairs: (data['repairs'] as List? ?? []).map((e) => AssetRepair.fromJson(e)).toList(),
    );
  }

  Future<List<AssetRepair>> getAssetRepairs({int? assetId}) async {
    final params = <String, String>{'action': 'asset_repairs'};
    if (assetId != null) params['asset_id'] = assetId.toString();

    final data = await _get('asset_repairs', params);
    return (data['repairs'] as List? ?? []).map((e) => AssetRepair.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> addAsset({
    required String name,
    required String type,
    String? brand,
    String? model,
    String? serialNumber,
    String? purchaseDate,
    double? purchasePrice,
    String? vendor,
    int? assignedTo,
    String status = 'active',
    String? warrantyExpiry,
    String? notes,
    String? remarks,
    int checkupInterval = 90,
  }) async {
    return await _post({
      'action': 'asset_add',
      'name': name,
      'type': type,
      'brand': brand ?? '',
      'model': model ?? '',
      'serial_number': serialNumber ?? '',
      'purchase_date': purchaseDate,
      'purchase_price': purchasePrice,
      'vendor': vendor ?? '',
      'assigned_to': assignedTo,
      'status': status,
      'warranty_expiry': warrantyExpiry,
      'notes': notes ?? '',
      'remarks': remarks ?? '',
      'checkup_interval': checkupInterval,
    });
  }

  Future<Map<String, dynamic>> updateAsset(int id, {
    String? name,
    String? type,
    String? brand,
    String? model,
    String? serialNumber,
    String? purchaseDate,
    double? purchasePrice,
    String? vendor,
    int? assignedTo,
    String? status,
    String? warrantyExpiry,
    String? notes,
    String? remarks,
    int? checkupInterval,
  }) async {
    final body = <String, dynamic>{
      'action': 'asset_update',
      'id': id,
    };
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (brand != null) body['brand'] = brand;
    if (model != null) body['model'] = model;
    if (serialNumber != null) body['serial_number'] = serialNumber;
    if (purchaseDate != null) body['purchase_date'] = purchaseDate;
    if (purchasePrice != null) body['purchase_price'] = purchasePrice;
    if (vendor != null) body['vendor'] = vendor;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (status != null) body['status'] = status;
    if (warrantyExpiry != null) body['warranty_expiry'] = warrantyExpiry;
    if (notes != null) body['notes'] = notes;
    if (remarks != null) body['remarks'] = remarks;
    if (checkupInterval != null) body['checkup_interval'] = checkupInterval;

    return await _post(body);
  }

  Future<Map<String, dynamic>> deleteAsset(int id) async {
    return await _post({
      'action': 'asset_delete',
      'id': id,
    });
  }

  Future<Map<String, dynamic>> assignAsset(int assetId, int? staffId, {String? notes}) async {
    return await _post({
      'action': 'asset_assign',
      'asset_id': assetId,
      'staff_id': staffId,
      'notes': notes ?? '',
    });
  }

  Future<Map<String, dynamic>> addRepair({
    required int assetId,
    required String date,
    required String issue,
    double? cost,
    String? vendor,
    String status = 'pending',
    String? notes,
  }) async {
    return await _post({
      'action': 'asset_add_repair',
      'asset_id': assetId,
      'date': date,
      'issue': issue,
      'cost': cost ?? 0,
      'vendor': vendor ?? '',
      'status': status,
      'notes': notes ?? '',
    });
  }

  // ========== PROJECTS ==========

  Future<({List<Project> projects, int total})> getProjects({
    String? search,
    String? status,
    int? lead,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'action': 'project_list',
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (lead != null) params['lead'] = lead.toString();

    final data = await _get('project_list', params);
    final projects = (data['projects'] as List? ?? []).map((e) => Project.fromJson(e)).toList();
    return (
      projects: projects,
      total: int.tryParse(data['total']?.toString() ?? '0') ?? projects.length,
    );
  }

  Future<Map<String, dynamic>> getProjectsBoard({
    String? search,
    int? lead,
  }) async {
    final params = <String, String>{
      'action': 'projects_board',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (lead != null) params['lead'] = lead.toString();

    return await _get('projects_board', params);
  }

  Future<ProjectDetail> getProjectDetail(int projectId) async {
    final data = await _get('project_detail', {'id': projectId.toString()});
    return ProjectDetail.fromJson(data);
  }

  Future<List<ProjectActivity>> getProjectActivity() async {
    final data = await _get('project_activity');
    return (data['activity'] as List? ?? []).map((e) => ProjectActivity.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> addProject({
    required String name,
    String? description,
    String status = 'active',
    int? projectLead,
    String? startDate,
    String? targetDate,
  }) async {
    return await _post({
      'action': 'project_add',
      'name': name,
      'description': description ?? '',
      'status': status,
      'project_lead': projectLead,
      'start_date': startDate,
      'target_date': targetDate,
    });
  }

  Future<Map<String, dynamic>> updateProject(
    int id, {
    String? name,
    String? description,
    String? status,
    int? projectLead,
    String? startDate,
    String? targetDate,
  }) async {
    final body = <String, dynamic>{
      'action': 'project_update',
      'id': id,
    };
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    if (projectLead != null) body['project_lead'] = projectLead;
    if (startDate != null) body['start_date'] = startDate;
    if (targetDate != null) body['target_date'] = targetDate;

    return await _post(body);
  }

  Future<Map<String, dynamic>> deleteProject(int id) async {
    return await _post({
      'action': 'project_delete',
      'id': id,
    });
  }

  Future<Map<String, dynamic>> moveProject(int projectId, String newStatus) async {
    return await _post({
      'action': 'project_move',
      'project_id': projectId,
      'new_status': newStatus,
    });
  }

  Future<Map<String, dynamic>> addProjectTask({
    required int projectId,
    required String title,
    String? description,
    int? assignedTo,
    String priority = 'normal',
    String? dueDate,
  }) async {
    return await _post({
      'action': 'task_create',
      'title': title,
      'description': description ?? '',
      'assignees': assignedTo != null ? [assignedTo] : [],
      'priority': priority,
      'due_date': dueDate,
      'category': 'other',
      'project_id': projectId,
    });
  }
}
