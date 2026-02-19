import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'mobile_token';
  static const _staffIdKey = 'staff_id';
  static const _staffNameKey = 'staff_name';
  static const _staffRoleKey = 'staff_role';
  static const _mobileKey = 'login_mobile';
  static const _pinKey = 'login_pin';

  final ApiService _api = ApiService();

  Future<({bool ok, String? error, Map<String, dynamic>? staff})> login(String mobile, String pin) async {
    try {
      final result = await _api.mobileLogin(mobile, pin);
      if (result['ok'] == true) {
        final token = result['token'] as String;
        final staff = result['staff'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setInt(_staffIdKey, staff['id']);
        await prefs.setString(_staffNameKey, staff['name']);
        await prefs.setString(_staffRoleKey, staff['role']);
        // Save credentials for silent re-login when token expires
        await prefs.setString(_mobileKey, mobile);
        await prefs.setString(_pinKey, pin);
        _api.setToken(token);
        return (ok: true, error: null, staff: staff);
      }
      return (ok: false, error: (result['error'] ?? 'Login failed') as String, staff: null);
    } catch (e) {
      return (ok: false, error: 'Network error: $e', staff: null);
    }
  }

  /// Try to silently re-login using saved credentials
  Future<bool> _silentReLogin(SharedPreferences prefs) async {
    final mobile = prefs.getString(_mobileKey);
    final pin = prefs.getString(_pinKey);
    if (mobile == null || pin == null) return false;

    try {
      final result = await _api.mobileLogin(mobile, pin);
      if (result['ok'] == true) {
        final token = result['token'] as String;
        final staff = result['staff'] as Map<String, dynamic>;
        await prefs.setString(_tokenKey, token);
        await prefs.setInt(_staffIdKey, staff['id']);
        await prefs.setString(_staffNameKey, staff['name']);
        await prefs.setString(_staffRoleKey, staff['role']);
        _api.setToken(token);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<({bool loggedIn, int? staffId, String? name, String? role})> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      // No token but maybe saved credentials — try silent re-login
      if (await _silentReLogin(prefs)) {
        return _cachedSession(prefs);
      }
      return (loggedIn: false, staffId: null, name: null, role: null);
    }

    try {
      final result = await _api.verifyToken(token);
      if (result['ok'] == true) {
        _api.setToken(token);
        final staff = result['staff'];
        return (loggedIn: true, staffId: staff['id'] as int?, name: staff['name'] as String?, role: staff['role'] as String?);
      }
      // Token expired — try silent re-login to get a fresh token
      if (await _silentReLogin(prefs)) {
        return _cachedSession(prefs);
      }
      await prefs.clear();
      return (loggedIn: false, staffId: null, name: null, role: null);
    } catch (_) {
      // Network error — use cached credentials so app works offline
      final id = prefs.getInt(_staffIdKey);
      if (id != null) {
        _api.setToken(token);
        return (loggedIn: true, staffId: id, name: prefs.getString(_staffNameKey), role: prefs.getString(_staffRoleKey));
      }
    }
    return (loggedIn: false, staffId: null, name: null, role: null);
  }

  ({bool loggedIn, int? staffId, String? name, String? role}) _cachedSession(SharedPreferences prefs) {
    final id = prefs.getInt(_staffIdKey);
    final name = prefs.getString(_staffNameKey);
    final role = prefs.getString(_staffRoleKey);
    return (loggedIn: true, staffId: id, name: name, role: role);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      try { await _api.mobileLogout(token); } catch (_) {}
    }
    _api.setToken(null);
    await prefs.clear();
  }
}
