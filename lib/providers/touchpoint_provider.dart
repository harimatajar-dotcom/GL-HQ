import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TouchpointCustomer {
  final int id;
  final String name;
  final String? company;
  final String phone;
  final String? email;
  final String subscriptionType;
  final DateTime startDate;
  final DateTime expiryDate;
  final String status;
  final String health;
  final String? notes;

  TouchpointCustomer({
    required this.id,
    required this.name,
    this.company,
    required this.phone,
    this.email,
    required this.subscriptionType,
    required this.startDate,
    required this.expiryDate,
    required this.status,
    required this.health,
    this.notes,
  });

  factory TouchpointCustomer.fromJson(Map<String, dynamic> json) => TouchpointCustomer(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? '',
    company: json['company'],
    phone: json['phone'] ?? '',
    email: json['email'],
    subscriptionType: json['subscription_type'] ?? 'free_trial',
    startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
    expiryDate: DateTime.tryParse(json['expiry_date'] ?? '') ?? DateTime.now(),
    status: json['status'] ?? 'active',
    health: json['health'] ?? 'unknown',
    notes: json['notes'],
  );

  bool get isHealthy => health == 'healthy';
  bool get isAtRisk => health == 'at_risk';
  bool get isCritical => health == 'critical' || health == 'churning';
  bool get isTrial => subscriptionType.contains('trial');
  bool get isPaid => !isTrial;

  String get subscriptionLabel {
    return switch (subscriptionType) {
      'free_trial' => 'Free Trial',
      'extended_trial' => 'Extended Trial',
      '1_month' => '1 Month',
      '3_month' => '3 Months',
      '1_year' => '1 Year',
      _ => subscriptionType,
    };
  }

  String get healthLabel {
    return switch (health) {
      'healthy' => 'Healthy',
      'at_risk' => 'At Risk',
      'critical' => 'Critical',
      'churning' => 'Churning',
      _ => 'Unknown',
    };
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}

class TouchpointData {
  final int id;
  final int customerId;
  final String stage;
  final DateTime dueDate;
  final int? assignedTo;
  final String status;
  final String? outcome;
  final String? outcomeNotes;
  final DateTime? completedAt;

  TouchpointData({
    required this.id,
    required this.customerId,
    required this.stage,
    required this.dueDate,
    this.assignedTo,
    required this.status,
    this.outcome,
    this.outcomeNotes,
    this.completedAt,
  });

  factory TouchpointData.fromJson(Map<String, dynamic> json) => TouchpointData(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
    stage: json['stage'] ?? '',
    dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
    assignedTo: json['assigned_to'] != null ? int.tryParse(json['assigned_to'].toString()) : null,
    status: json['status'] ?? 'pending',
    outcome: json['outcome'],
    outcomeNotes: json['outcome_notes'],
    completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
  );

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  String get stageLabel {
    final labels = {
      'usage_check': 'Usage Check',
      'payment': 'Payment Collection',
      'welcome_call': '🚀 Welcome Call',
      'setup_check': '🚀 Setup Check',
      'feature_walkthrough': '🚀 Feature Walkthrough',
      'usage_checkin': '🚀 Usage Check-in',
      'conversion_nudge': '🚀 Conversion Nudge',
      'extended_checkin': '🚀 Extended Check-in',
      'final_conversion': '🚀 Final Conversion',
    };
    return labels[stage] ?? stage;
  }
}

class TPDashboardStats {
  final int overdue;
  final int today;
  final int upcoming;
  final int completedWeek;
  final Map<String, int> health;
  final List<Map<String, dynamic>> renewals;

  TPDashboardStats({
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.completedWeek,
    required this.health,
    required this.renewals,
  });

  factory TPDashboardStats.fromJson(Map<String, dynamic> json) => TPDashboardStats(
    overdue: json['overdue'] ?? 0,
    today: json['today'] ?? 0,
    upcoming: json['upcoming'] ?? 0,
    completedWeek: json['completed_week'] ?? 0,
    health: {
      'healthy': json['health']?['healthy'] ?? 0,
      'at_risk': json['health']?['at_risk'] ?? 0,
      'critical': json['health']?['critical'] ?? 0,
      'unknown': json['health']?['unknown'] ?? 0,
    },
    renewals: (json['renewals'] as List? ?? []).cast<Map<String, dynamic>>(),
  );
}

class TouchpointProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  TPDashboardStats? _dashboard;
  List<TouchpointCustomer> _customers = [];
  List<TouchpointData> _touchpoints = [];

  bool _loading = false;
  String? _error;
  String _filterStatus = '';
  String _filterSubscription = '';
  String _searchQuery = '';

  TPDashboardStats? get dashboard => _dashboard;
  List<TouchpointCustomer> get customers => _filteredCustomers;
  List<TouchpointData> get touchpoints => _touchpoints;
  bool get loading => _loading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  String get filterSubscription => _filterSubscription;
  String get searchQuery => _searchQuery;

  List<TouchpointCustomer> get _filteredCustomers {
    return _customers.where((c) {
      if (_filterStatus.isNotEmpty && c.status != _filterStatus) return false;
      if (_filterSubscription.isNotEmpty && c.subscriptionType != _filterSubscription) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(query) ||
               c.phone.contains(query) ||
               (c.company?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();
  }

  void setStatusFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSubscriptionFilter(String subscription) {
    _filterSubscription = subscription;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = '';
    _filterSubscription = '';
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.tpDashboard();
      if (data['ok'] == true) {
        _dashboard = TPDashboardStats.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.tpCustomers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _filterStatus.isNotEmpty ? _filterStatus : null,
        subscription: _filterSubscription.isNotEmpty ? _filterSubscription : null,
      );
      if (data['ok'] == true) {
        _customers = (data['customers'] as List? ?? [])
            .map((e) => TouchpointCustomer.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTouchpoints({String? stage, String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.tpTouchpoints(
        stage: stage,
        status: status,
      );
      if (data['ok'] == true) {
        _touchpoints = (data['touchpoints'] as List? ?? [])
            .map((e) => TouchpointData.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> completeTouchpoint(int touchpointId, String outcome, {String? notes}) async {
    try {
      // This would need a new API endpoint
      // For now, we'll refresh the list
      await loadTouchpoints();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadDashboard(),
      loadCustomers(),
    ]);
  }
}
