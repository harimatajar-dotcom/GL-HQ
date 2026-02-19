import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ChatSession {
  final String id;
  final String? staffName;
  final int? staffId;
  final DateTime? lastActivity;
  final int messageCount;
  final String? channel;

  ChatSession({
    required this.id,
    this.staffName,
    this.staffId,
    this.lastActivity,
    required this.messageCount,
    this.channel,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['session_id'] ?? json['id'] ?? '',
    staffName: json['staff_name'],
    staffId: json['staff_id'] != null ? int.tryParse(json['staff_id'].toString()) : null,
    lastActivity: json['last_activity'] != null 
        ? DateTime.tryParse(json['last_activity']) 
        : null,
    messageCount: int.tryParse(json['message_count']?.toString() ?? '0') ?? 0,
    channel: json['channel'] ?? 'telegram',
  );

  String get displayName => staffName ?? 'Unknown User';
  String get shortId => id.length > 8 ? '${id.substring(0, 8)}...' : id;
}

class ChatLog {
  final int id;
  final String? sessionId;
  final int? staffId;
  final String? staffName;
  final String role;
  final String message;
  final String channel;
  final DateTime createdAt;
  final int? messageId;

  ChatLog({
    required this.id,
    this.sessionId,
    this.staffId,
    this.staffName,
    required this.role,
    required this.message,
    required this.channel,
    required this.createdAt,
    this.messageId,
  });

  factory ChatLog.fromJson(Map<String, dynamic> json) => ChatLog(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    sessionId: json['session_id'],
    staffId: json['staff_id'] != null ? int.tryParse(json['staff_id'].toString()) : null,
    staffName: json['staff_name'],
    role: json['role'] ?? 'user',
    message: json['message'] ?? '',
    channel: json['channel'] ?? 'telegram',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    messageId: json['message_id'] != null ? int.tryParse(json['message_id'].toString()) : null,
  );

  bool get isUser => role == 'user' || role == 'staff';
  bool get isAssistant => role == 'assistant' || role == 'bot';
  bool get isSystem => role == 'system';

  String get displayName => staffName ?? (isAssistant ? 'Assistant' : 'User');
}

class ChatlogsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ChatSession> _sessions = [];
  List<ChatLog> _logs = [];
  ChatSession? _selectedSession;

  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  String _searchQuery = '';
  String? _filterStaffName;
  DateTime? _filterDate;

  List<ChatSession> get sessions => _sessions;
  List<ChatLog> get logs => _logs;
  ChatSession? get selectedSession => _selectedSession;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _sessions = [];
    _hasMore = true;
    notifyListeners();
    if (query.isNotEmpty) {
      searchLogs();
    } else {
      loadSessions();
    }
  }

  void setFilterStaff(String? staffName) {
    _filterStaffName = staffName;
    _currentPage = 1;
    notifyListeners();
    loadSessions();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    _currentPage = 1;
    notifyListeners();
    loadSessions();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStaffName = null;
    _filterDate = null;
    _currentPage = 1;
    notifyListeners();
    loadSessions();
  }

  void selectSession(ChatSession? session) {
    _selectedSession = session;
    _logs = [];
    notifyListeners();
    if (session != null) {
      loadSessionLogs(session.id);
    }
  }

  void clearSelection() {
    _selectedSession = null;
    _logs = [];
    notifyListeners();
  }

  Future<void> loadSessions() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getChatSessions();
      _sessions = (result.sessions as List? ?? [])
          .map((e) => ChatSession.fromJson(e))
          .toList();
      
      // Sort by last activity, newest first
      _sessions.sort((a, b) {
        if (a.lastActivity == null && b.lastActivity == null) return 0;
        if (a.lastActivity == null) return 1;
        if (b.lastActivity == null) return -1;
        return b.lastActivity!.compareTo(a.lastActivity!);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionLogs(String sessionId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getChatLogs(
        sessionId: sessionId,
        limit: 100,
      );
      _logs = (result.logs as List? ?? [])
          .map((e) => ChatLog.fromJson(e))
          .toList();
      
      // Sort by created_at ascending (oldest first for chat display)
      _logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> searchLogs() async {
    if (_searchQuery.isEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getChatLogs(
        search: _searchQuery,
        page: _currentPage,
        limit: 50,
      );
      
      final newLogs = (result.logs as List? ?? [])
          .map((e) => ChatLog.fromJson(e))
          .toList();
      
      if (_currentPage == 1) {
        _logs = newLogs;
      } else {
        _logs.addAll(newLogs);
      }
      
      _hasMore = newLogs.length >= 50;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _currentPage++;
    await searchLogs();
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    if (_selectedSession != null) {
      await loadSessionLogs(_selectedSession!.id);
    } else if (_searchQuery.isNotEmpty) {
      await searchLogs();
    } else {
      await loadSessions();
    }
  }
}
