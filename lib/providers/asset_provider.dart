import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../services/api_service.dart';

class AssetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Asset> _assets = [];
  List<Asset> _myAssets = [];
  bool _loading = false;
  bool _myAssetsLoading = false;
  int _total = 0;
  int _currentPage = 1;
  String? _statusFilter;
  String? _categoryFilter;
  String? _assignedToFilter;
  String? _search;
  String? _error;

  List<Asset> get assets => _assets;
  List<Asset> get myAssets => _myAssets;
  bool get loading => _loading;
  bool get myAssetsLoading => _myAssetsLoading;
  int get total => _total;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  String? get assignedToFilter => _assignedToFilter;
  String? get search => _search;
  String? get error => _error;
  bool get hasMore => _assets.length < _total;

  void setStatusFilter(String? s) {
    _statusFilter = s;
    refresh();
  }

  void setCategoryFilter(String? c) {
    _categoryFilter = c;
    refresh();
  }

  void setAssignedToFilter(String? a) {
    _assignedToFilter = a;
    refresh();
  }

  void setSearch(String? q) {
    _search = q;
    refresh();
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.getAssets(
        search: _search,
        status: _statusFilter,
        category: _categoryFilter,
        page: 1,
        limit: 50,
      );
      _assets = result.assets;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;

    _currentPage++;
    _loading = true;
    notifyListeners();

    try {
      final result = await _api.getAssets(
        search: _search,
        status: _statusFilter,
        category: _categoryFilter,
        page: _currentPage,
        limit: 50,
      );
      _assets.addAll(result.assets);
      _total = result.total;
    } catch (e) {
      _error = e.toString();
      _currentPage--;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMyAssets(int staffId) async {
    _myAssetsLoading = true;
    notifyListeners();

    try {
      final result = await _api.getAssets(
        assignedTo: staffId,
        status: 'active',
        page: 1,
        limit: 100,
      );
      _myAssets = result.assets;
    } catch (e) {
      _error = e.toString();
    }

    _myAssetsLoading = false;
    notifyListeners();
  }

  Future<void> addAsset({
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
    await _api.addAsset(
      name: name,
      type: type,
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      vendor: vendor,
      assignedTo: assignedTo,
      status: status,
      warrantyExpiry: warrantyExpiry,
      notes: notes,
      remarks: remarks,
      checkupInterval: checkupInterval,
    );
    await refresh();
  }

  Future<void> updateAsset(int id, {
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
    await _api.updateAsset(
      id,
      name: name,
      type: type,
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      vendor: vendor,
      assignedTo: assignedTo,
      status: status,
      warrantyExpiry: warrantyExpiry,
      notes: notes,
      remarks: remarks,
      checkupInterval: checkupInterval,
    );
    await refresh();
  }

  Future<void> deleteAsset(int id) async {
    await _api.deleteAsset(id);
    await refresh();
  }

  Future<void> assignAsset(int assetId, int? staffId, {String? notes}) async {
    await _api.assignAsset(assetId, staffId, notes: notes);
    await refresh();
  }

  Future<void> addRepair({
    required int assetId,
    required String date,
    required String issue,
    double? cost,
    String? vendor,
    String status = 'pending',
    String? notes,
  }) async {
    await _api.addRepair(
      assetId: assetId,
      date: date,
      issue: issue,
      cost: cost,
      vendor: vendor,
      status: status,
      notes: notes,
    );
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _assignedToFilter = null;
    _search = null;
    refresh();
  }
}
