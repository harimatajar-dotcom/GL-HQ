import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _loggedIn = false;
  int? _staffId;
  String? _name;
  String? _role;

  bool get loading => _loading;
  bool get loggedIn => _loggedIn;
  int? get staffId => _staffId;
  String? get name => _name;
  String? get role => _role;
  bool get isAdmin => _role == 'admin' || _role == 'secretary';

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    final session = await _auth.checkSession();
    _loggedIn = session.loggedIn;
    _staffId = session.staffId;
    _name = session.name;
    _role = session.role;
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String mobile, String pin) async {
    final result = await _auth.login(mobile, pin);
    if (result.ok) {
      _loggedIn = true;
      _staffId = result.staff!['id'];
      _name = result.staff!['name'];
      _role = result.staff!['role'];
      notifyListeners();
      return null;
    }
    return result.error;
  }

  Future<void> logout() async {
    await _auth.logout();
    _loggedIn = false;
    _staffId = null;
    _name = null;
    _role = null;
    notifyListeners();
  }
}
