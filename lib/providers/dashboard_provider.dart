import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/my_dashboard.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DashboardStats? _adminStats;
  MyDashboard? _myDashboard;
  bool _loading = false;
  String? _error;

  DashboardStats? get adminStats => _adminStats;
  MyDashboard? get myDashboard => _myDashboard;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAdminDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _adminStats = await _api.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMyDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _myDashboard = await _api.getMyDashboard();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
