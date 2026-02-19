import 'package:flutter/material.dart';

class AppColors {
  // Core
  static const background = Colors.white;
  static const foreground = Color(0xFF18181B);
  static const primary = Color(0xFF18181B);
  static const accent = Color(0xFF14B8A6);
  static const accentLight = Color(0xFFCCFBF1);

  // Neutral
  static const muted = Color(0xFFF4F4F5);
  static const mutedForeground = Color(0xFF71717A);
  static const border = Color(0xFFE4E4E7);
  static const card = Colors.white;

  // Semantic
  static const destructive = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF3B82F6);
  static const teal = Color(0xFF14B8A6);
  static const slate = Color(0xFF64748B);

  // Priority colors
  static Color priorityColor(String priority) => switch (priority) {
    'urgent' => destructive,
    'high' => amber,
    'normal' => blue,
    'low' => slate,
    _ => slate,
  };

  // Status colors
  static Color statusColor(String status) => switch (status) {
    'pending' => amber,
    'in_progress' => blue,
    'done' => green,
    'blocked' => destructive,
    _ => slate,
  };

  // Status background (light)
  static Color statusBg(String status) => switch (status) {
    'pending' => const Color(0xFFFEF3C7),
    'in_progress' => const Color(0xFFDBEAFE),
    'done' => const Color(0xFFD1FAE5),
    'blocked' => const Color(0xFFFEE2E2),
    _ => muted,
  };
}

class AppConstants {
  static const apiBase = 'https://akhilkrishna.com/hq/api.php';
  static const submitUrl = 'https://akhilkrishna.com/hq/submit.php';
  static const apiToken = 'gl_reports_2026';

  static const roleEmojis = {
    'sales_rep': '💼',
    'secretary': '📋',
    'support': '🎧',
    'hr': '👥',
    'finance': '💰',
    'developer': '💻',
    'tester': '🧪',
    'admin': '⚡',
  };

  static const roleLabels = {
    'sales_rep': 'Sales Rep',
    'secretary': 'Secretary',
    'support': 'Support',
    'hr': 'HR',
    'finance': 'Finance',
    'developer': 'Developer',
    'tester': 'Tester',
    'admin': 'Admin',
  };

  static const categoryEmojis = {
    'sales': '💼',
    'development': '💻',
    'support': '🎧',
    'hr': '👥',
    'finance': '💰',
    'operations': '⚙️',
    'other': '📌',
  };

  static bool isAdmin(String role) => role == 'admin' || role == 'secretary';
}
