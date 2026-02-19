import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class ProjectsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Project> _projects = [];
  bool _loading = false;
  bool _boardLoading = false;
  String? _error;
  String? _statusFilter;
  String? _search;
  int? _leadFilter;
  
  // Board view data
  Map<String, List<Project>> _board = {
    'active': [],
    'on_hold': [],
    'completed': [],
    'archived': [],
  };

  List<Project> get projects => _projects;
  bool get loading => _loading;
  bool get boardLoading => _boardLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get search => _search;
  int? get leadFilter => _leadFilter;
  Map<String, List<Project>> get board => _board;

  int get totalProjects => _projects.length;
  int get activeCount => _projects.where((p) => p.status == 'active').length;
  int get onHoldCount => _projects.where((p) => p.status == 'on_hold').length;
  int get completedCount => _projects.where((p) => p.status == 'completed').length;
  int get archivedCount => _projects.where((p) => p.status == 'archived').length;

  void setStatusFilter(String? status) {
    _statusFilter = status;
    refresh();
  }

  void setSearch(String? query) {
    _search = query?.isEmpty == true ? null : query;
    refresh();
  }

  void setLeadFilter(int? leadId) {
    _leadFilter = leadId;
    refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getProjects(
        search: _search,
        status: _statusFilter,
        lead: _leadFilter,
        page: 1,
        limit: 50,
      );
      _projects = result.projects;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadBoard() async {
    _boardLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getProjectsBoard(
        search: _search,
        lead: _leadFilter,
      );
      
      if (data['ok'] == true && data['board'] != null) {
        final boardData = data['board'] as Map<String, dynamic>;
        _board = {
          'active': (boardData['active'] as List? ?? [])
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
          'on_hold': (boardData['on_hold'] as List? ?? [])
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
          'completed': (boardData['completed'] as List? ?? [])
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
          'archived': (boardData['archived'] as List? ?? [])
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
        };
      }
    } catch (e) {
      _error = e.toString();
    }

    _boardLoading = false;
    notifyListeners();
  }

  Future<bool> addProject({
    required String name,
    String? description,
    String status = 'active',
    int? projectLead,
    String? startDate,
    String? targetDate,
  }) async {
    try {
      final result = await _api.addProject(
        name: name,
        description: description,
        status: status,
        projectLead: projectLead,
        startDate: startDate,
        targetDate: targetDate,
      );
      
      if (result['ok'] == true) {
        await refresh();
        return true;
      }
      _error = result['error']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProject(
    int id, {
    String? name,
    String? description,
    String? status,
    int? projectLead,
    String? startDate,
    String? targetDate,
  }) async {
    try {
      final result = await _api.updateProject(
        id,
        name: name,
        description: description,
        status: status,
        projectLead: projectLead,
        startDate: startDate,
        targetDate: targetDate,
      );
      
      if (result['ok'] == true) {
        await refresh();
        return true;
      }
      _error = result['error']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProject(int id) async {
    try {
      final result = await _api.deleteProject(id);
      
      if (result['ok'] == true) {
        await refresh();
        return true;
      }
      _error = result['error']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> moveProject(int projectId, String newStatus) async {
    try {
      final result = await _api.moveProject(projectId, newStatus);
      
      if (result['ok'] == true) {
        await loadBoard();
        return true;
      }
      _error = result['error']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProjectTask({
    required int projectId,
    required String title,
    String? description,
    int? assignedTo,
    String priority = 'normal',
    String? dueDate,
  }) async {
    try {
      final result = await _api.addProjectTask(
        projectId: projectId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        priority: priority,
        dueDate: dueDate,
      );
      
      if (result['ok'] == true) {
        return true;
      }
      _error = result['error']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
