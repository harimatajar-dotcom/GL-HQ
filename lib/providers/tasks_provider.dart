import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TasksProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  bool _loading = false;
  int _total = 0;
  int _pages = 1;
  int _currentPage = 1;
  String? _statusFilter;
  String? _priorityFilter;
  String? _search;
  bool _showAllTasks = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  int get total => _total;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  bool get showAllTasks => _showAllTasks;
  bool get hasMore => _currentPage < _pages;
  String? get error => _error;

  void setStatusFilter(String? s) {
    _statusFilter = s;
    refresh();
  }

  void setPriorityFilter(String? p) {
    _priorityFilter = p;
    refresh();
  }

  void setSearch(String? q) {
    _search = q;
    refresh();
  }

  void toggleAllTasks() {
    _showAllTasks = !_showAllTasks;
    refresh();
  }

  int? _lastStaffId;

  Future<void> refresh({int? staffId}) async {
    if (staffId != null) _lastStaffId = staffId;
    _currentPage = 1;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getTasks(
        assignedTo: _showAllTasks ? null : _lastStaffId,
        status: _statusFilter,
        priority: _priorityFilter,
        search: _search,
        page: 1,
      );
      _tasks = result.tasks;
      _total = result.total;
      _pages = result.pages;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_currentPage >= _pages || _loading) return;
    _currentPage++;
    try {
      final result = await _api.getTasks(
        assignedTo: _showAllTasks ? null : _lastStaffId,
        status: _statusFilter,
        priority: _priorityFilter,
        search: _search,
        page: _currentPage,
      );
      _tasks.addAll(result.tasks);
      notifyListeners();
    } catch (_) {
      _currentPage--;
    }
  }
}
