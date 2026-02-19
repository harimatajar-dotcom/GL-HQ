import 'package:flutter/material.dart';
import '../config/constants.dart';

class Asset {
  final int id;
  final String? assetTag;
  final String name;
  final String type;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? purchaseDate;
  final double? purchasePrice;
  final String? vendor;
  final int? assignedTo;
  final String status;
  final String? warrantyExpiry;
  final String? notes;
  final String? remarks;
  final String? lastCheckup;
  final String? nextCheckup;
  final int? checkupInterval;
  final String? createdAt;
  final String? updatedAt;
  final String? ownerName;

  Asset({
    required this.id,
    this.assetTag,
    required this.name,
    required this.type,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.vendor,
    this.assignedTo,
    this.status = 'active',
    this.warrantyExpiry,
    this.notes,
    this.remarks,
    this.lastCheckup,
    this.nextCheckup,
    this.checkupInterval,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    assetTag: json['asset_tag'],
    name: json['name'] ?? '',
    type: json['type'] ?? 'other',
    brand: json['brand'],
    model: json['model'],
    serialNumber: json['serial_number'],
    purchaseDate: json['purchase_date'],
    purchasePrice: json['purchase_price'] != null 
      ? double.tryParse(json['purchase_price'].toString()) 
      : null,
    vendor: json['vendor'],
    assignedTo: json['assigned_to'] != null 
      ? int.tryParse(json['assigned_to'].toString()) 
      : null,
    status: json['status'] ?? 'active',
    warrantyExpiry: json['warranty_expiry'],
    notes: json['notes'],
    remarks: json['remarks'],
    lastCheckup: json['last_checkup'],
    nextCheckup: json['next_checkup'],
    checkupInterval: json['checkup_interval'] != null 
      ? int.tryParse(json['checkup_interval'].toString()) 
      : null,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
    ownerName: json['owner_name'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'asset_tag': assetTag,
    'name': name,
    'type': type,
    'brand': brand,
    'model': model,
    'serial_number': serialNumber,
    'purchase_date': purchaseDate,
    'purchase_price': purchasePrice,
    'vendor': vendor,
    'assigned_to': assignedTo,
    'status': status,
    'warranty_expiry': warrantyExpiry,
    'notes': notes,
    'remarks': remarks,
    'last_checkup': lastCheckup,
    'next_checkup': nextCheckup,
    'checkup_interval': checkupInterval,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'owner_name': ownerName,
  };

  bool get isWarrantyExpired {
    if (warrantyExpiry == null) return false;
    final expiry = DateTime.tryParse(warrantyExpiry!);
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool get isCheckupDue {
    if (nextCheckup == null) return false;
    final due = DateTime.tryParse(nextCheckup!);
    return due != null && !due.isAfter(DateTime.now());
  }

  String get age {
    if (purchaseDate == null) return '—';
    final purchase = DateTime.tryParse(purchaseDate!);
    if (purchase == null) return '—';
    
    final now = DateTime.now();
    final diff = now.difference(purchase);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    
    if (years > 0) return '${years}y ${months}m';
    if (months > 0) return '${months}m';
    return '${diff.inDays}d';
  }

  static Color statusColor(String status) => switch (status) {
    'active' => AppColors.green,
    'in_repair' => AppColors.amber,
    'retired' => AppColors.slate,
    'lost' => AppColors.destructive,
    _ => AppColors.slate,
  };

  static Color statusBgColor(String status) => switch (status) {
    'active' => const Color(0xFFD1FAE5),
    'in_repair' => const Color(0xFFFEF3C7),
    'retired' => const Color(0xFFF1F5F9),
    'lost' => const Color(0xFFFEE2E2),
    _ => const Color(0xFFF1F5F9),
  };

  static String statusLabel(String status) => switch (status) {
    'active' => 'Available',
    'in_repair' => 'In Repair',
    'retired' => 'Retired',
    'lost' => 'Lost',
    _ => status,
  };

  static const List<String> types = [
    'laptop',
    'mobile',
    'monitor',
    'printer',
    'networking',
    'furniture',
    'other',
  ];

  static const List<String> statuses = [
    'active',
    'in_repair',
    'retired',
    'lost',
  ];
}

class AssetAssignment {
  final int id;
  final int assetId;
  final int staffId;
  final String assignedAt;
  final String? returnedAt;
  final String? notes;
  final String? staffName;

  AssetAssignment({
    required this.id,
    required this.assetId,
    required this.staffId,
    required this.assignedAt,
    this.returnedAt,
    this.notes,
    this.staffName,
  });

  factory AssetAssignment.fromJson(Map<String, dynamic> json) => AssetAssignment(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    assetId: json['asset_id'] is int ? json['asset_id'] : int.parse(json['asset_id'].toString()),
    staffId: json['staff_id'] is int ? json['staff_id'] : int.parse(json['staff_id'].toString()),
    assignedAt: json['assigned_at'] ?? '',
    returnedAt: json['returned_at'],
    notes: json['notes'],
    staffName: json['staff_name'],
  );

  String get duration {
    if (assignedAt.isEmpty) return '—';
    final start = DateTime.tryParse(assignedAt);
    if (start == null) return '—';
    
    final end = returnedAt != null ? DateTime.tryParse(returnedAt!) : DateTime.now();
    if (end == null) return '—';
    
    final diff = end.difference(start);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    final days = diff.inDays % 30;
    
    if (years > 0) return '${years}y ${months}m ${days}d';
    if (months > 0) return '${months}m ${days}d';
    return '${days}d';
  }

  bool get isCurrent => returnedAt == null;
}

class AssetRepair {
  final int id;
  final int assetId;
  final String date;
  final String issue;
  final double? cost;
  final String? vendor;
  final String status;
  final String? notes;
  final String? assetName;
  final String? assetTag;

  AssetRepair({
    required this.id,
    required this.assetId,
    required this.date,
    required this.issue,
    this.cost,
    this.vendor,
    this.status = 'pending',
    this.notes,
    this.assetName,
    this.assetTag,
  });

  factory AssetRepair.fromJson(Map<String, dynamic> json) => AssetRepair(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    assetId: json['asset_id'] is int ? json['asset_id'] : int.parse(json['asset_id'].toString()),
    date: json['date'] ?? '',
    issue: json['issue'] ?? '',
    cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
    vendor: json['vendor'],
    status: json['status'] ?? 'pending',
    notes: json['notes'],
    assetName: json['asset_name'],
    assetTag: json['asset_tag'],
  );

  static Color statusColor(String status) => switch (status) {
    'completed' => AppColors.green,
    'pending' => AppColors.amber,
    _ => AppColors.slate,
  };

  static Color statusBgColor(String status) => switch (status) {
    'completed' => const Color(0xFFD1FAE5),
    'pending' => const Color(0xFFFEF3C7),
    _ => const Color(0xFFF1F5F9),
  };
}

class AssetCheckup {
  final int id;
  final int assetId;
  final int checkedBy;
  final String checkupDate;
  final String condition;
  final String? remarks;
  final String? checkerName;

  AssetCheckup({
    required this.id,
    required this.assetId,
    required this.checkedBy,
    required this.checkupDate,
    required this.condition,
    this.remarks,
    this.checkerName,
  });

  factory AssetCheckup.fromJson(Map<String, dynamic> json) => AssetCheckup(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    assetId: json['asset_id'] is int ? json['asset_id'] : int.parse(json['asset_id'].toString()),
    checkedBy: json['checked_by'] is int ? json['checked_by'] : int.parse(json['checked_by'].toString()),
    checkupDate: json['checkup_date'] ?? '',
    condition: json['condition'] ?? 'good',
    remarks: json['remarks'],
    checkerName: json['checker_name'],
  );

  static Color conditionColor(String condition) => switch (condition) {
    'good' => AppColors.green,
    'fair' => AppColors.amber,
    'poor' => AppColors.destructive,
    'damaged' => AppColors.destructive,
    'missing' => AppColors.slate,
    _ => AppColors.slate,
  };

  static Color conditionBgColor(String condition) => switch (condition) {
    'good' => const Color(0xFFD1FAE5),
    'fair' => const Color(0xFFFEF3C7),
    'poor' => const Color(0xFFFEE2E2),
    'damaged' => const Color(0xFFFEE2E2),
    'missing' => const Color(0xFFF1F5F9),
    _ => const Color(0xFFF1F5F9),
  };

  static String conditionLabel(String condition) => switch (condition) {
    'good' => '✅ Good',
    'fair' => '⚠️ Fair',
    'poor' => '🔴 Poor',
    'damaged' => '💥 Damaged',
    'missing' => '❓ Missing',
    _ => condition,
  };

  static const List<String> conditions = [
    'good',
    'fair',
    'poor',
    'damaged',
    'missing',
  ];
}
