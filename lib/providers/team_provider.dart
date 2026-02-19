import 'package:flutter/foundation.dart';
import '../models/staff.dart';
import '../services/api_service.dart';

class TeamProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Staff> _teamList = [];
  bool _loading = false;
  String? _error;

  List<Staff> get teamList => _teamList;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTeam() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _teamList = await _api.getTeamList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> toggleMember(int id) async {
    try {
      final result = await _api.toggleTeamMember(id);
      if (result['ok'] == true) {
        await loadTeam();
        return null;
      }
      return result['error'] ?? 'Failed to toggle member';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addMember(Map<String, dynamic> data) async {
    try {
      final result = await _api.addTeamMember(data);
      if (result['ok'] == true) {
        await loadTeam();
        return null;
      }
      return result['error'] ?? 'Failed to add member';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateMember(Map<String, dynamic> data) async {
    try {
      final result = await _api.updateTeamMember(data);
      if (result['ok'] == true) {
        await loadTeam();
        return null;
      }
      return result['error'] ?? 'Failed to update member';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteMember(int id) async {
    try {
      final result = await _api.deleteTeamMember(id);
      if (result['ok'] == true) {
        await loadTeam();
        return null;
      }
      return result['error'] ?? 'Failed to delete member';
    } catch (e) {
      return e.toString();
    }
  }
}
