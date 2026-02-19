import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _summary;
  List<dynamic> _missing = [];
  bool _loading = false;
  String? _error;
  String _selectedDate = '';

  Map<String, dynamic>? get summary => _summary;
  List<dynamic> get missing => _missing;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedDate => _selectedDate;

  Future<void> loadSummary(String date) async {
    _selectedDate = date;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _api.getSummary(date);
      _missing = await _api.getMissing();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<({bool ok, String? error})> submitReport(String date, Map<String, dynamic> data) async {
    final token = _api.token;
    debugPrint('REPORT: Submitting with token: ${token != null ? '${token.substring(0, 8)}...' : 'NULL'}');
    if (token == null) {
      return (ok: false, error: 'Session expired. Please login again.');
    }
    try {
      final result = await _api.submitReport(date, data);
      if (result['ok'] == true) {
        return (ok: true, error: null);
      }
      return (ok: false, error: (result['error'] as String?) ?? 'Submission failed');
    } catch (e) {
      return (ok: false, error: e.toString());
    }
  }
}
