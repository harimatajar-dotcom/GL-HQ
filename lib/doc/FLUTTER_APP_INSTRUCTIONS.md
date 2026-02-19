# Getlead HQ — Flutter Mobile App Complete Build Instructions

> **Purpose:** This document contains EVERYTHING needed to build the Getlead HQ Flutter mobile app from scratch. Paste this into Claude and ask it to build the app.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Backend Changes (PHP)](#2-backend-changes-php)
3. [Flutter Project Setup](#3-flutter-project-setup)
4. [File Structure](#4-file-structure)
5. [Design System](#5-design-system)
6. [Data Models](#6-data-models)
7. [API Service](#7-api-service)
8. [Auth Flow](#8-auth-flow)
9. [Screens — Detailed Specs](#9-screens)
10. [State Management](#10-state-management)
11. [Offline & Caching](#11-offline--caching)
12. [Build & Deploy](#12-build--deploy)

---

## 1. Project Overview

**App Name:** Getlead HQ
**Package:** `com.getlead.hq`
**What it is:** Team ERP mobile app for Getlead Analytics Pvt Ltd (CRM company, Kerala, India)
**Live web app:** https://akhilkrishna.com/hq/
**API base:** `https://akhilkrishna.com/hq/api.php`

### Roles & Permissions

| Role | Code | Emoji | Dashboard | All Tasks | Team Mgmt | Reports View | Daily Report |
|------|------|-------|-----------|-----------|-----------|-------------|-------------|
| Admin | `admin` | ⚡ | Admin | ✅ | ✅ | ✅ | ✅ |
| Secretary | `secretary` | 📋 | Admin | ✅ | ✅ | ✅ | ✅ |
| Sales Rep | `sales_rep` | 💼 | Personal | Own only | ❌ | ❌ | ✅ |
| Support | `support` | 🎧 | Personal | Own only | ❌ | ❌ | ✅ |
| HR | `hr` | 👥 | Personal | Own only | ❌ | ❌ | ✅ |
| Finance | `finance` | 💰 | Personal | Own only | ❌ | ❌ | ✅ |
| Developer | `developer` | 💻 | Personal | Own only | ❌ | ❌ | ✅ |
| Tester | `tester` | 🧪 | Personal | Own only | ❌ | ❌ | ✅ |

**Admin/Secretary** = elevated roles. They see admin dashboard, all tasks, team management, and reports view.
**All other roles** = staff. They see personal dashboard, their own tasks, and daily report submission.

---

## 2. Backend Changes (PHP)

### 2.1 Add Mobile Auth Endpoints to `api.php`

Add these cases to the POST switch statement in `api.php` **BEFORE** the existing session check:

```php
case 'mobile_login':
    $staff_id = intval($input['staff_id'] ?? 0);
    $pin = $input['pin'] ?? '';
    $stmt = $db->prepare("SELECT * FROM staff WHERE id = :id AND active = 1");
    $stmt->execute([':id' => $staff_id]);
    $staff = $stmt->fetch();
    if ($staff && password_verify($pin, $staff['pin'])) {
        $token = bin2hex(random_bytes(32));
        $db->exec("CREATE TABLE IF NOT EXISTS mobile_tokens (
            token TEXT PRIMARY KEY,
            staff_id INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME
        )");
        $expires = date('Y-m-d H:i:s', strtotime('+30 days'));
        $stmt2 = $db->prepare("INSERT INTO mobile_tokens (token, staff_id, expires_at) VALUES (:token, :sid, :exp)");
        $stmt2->execute([':token' => $token, ':sid' => $staff['id'], ':exp' => $expires]);
        echo json_encode([
            'ok' => true,
            'token' => $token,
            'staff' => [
                'id' => $staff['id'],
                'name' => $staff['name'],
                'role' => $staff['role']
            ]
        ]);
    } else {
        echo json_encode(['ok' => false, 'error' => 'Invalid credentials']);
    }
    exit;

case 'mobile_submit_report':
    $token = $input['token'] ?? '';
    $row = $db->prepare("SELECT mt.staff_id, s.name, s.role FROM mobile_tokens mt JOIN staff s ON mt.staff_id = s.id WHERE mt.token = :t AND mt.expires_at > datetime('now')");
    $row->execute([':t' => $token]);
    $auth = $row->fetch();
    if (!$auth) {
        echo json_encode(['ok' => false, 'error' => 'Invalid token']);
        exit;
    }
    $date = $input['date'] ?? date('Y-m-d');
    $reportData = json_encode($input['data'] ?? []);
    $existing = $db->prepare("SELECT id FROM daily_reports WHERE staff_id = :sid AND report_date = :d");
    $existing->execute([':sid' => $auth['staff_id'], ':d' => $date]);
    $existingId = $existing->fetchColumn();
    if ($existingId) {
        $stmt = $db->prepare("UPDATE daily_reports SET report_data = :data, updated_at = :now WHERE id = :id");
        $stmt->execute([':data' => $reportData, ':now' => date('Y-m-d H:i:s'), ':id' => $existingId]);
    } else {
        $stmt = $db->prepare("INSERT INTO daily_reports (staff_id, report_date, report_data, submitted_at) VALUES (:sid, :date, :data, :now)");
        $stmt->execute([':sid' => $auth['staff_id'], ':date' => $date, ':data' => $reportData, ':now' => date('Y-m-d H:i:s')]);
    }
    echo json_encode(['ok' => true, 'updated' => !!$existingId]);
    exit;

case 'mobile_my_dashboard':
    $token = $input['token'] ?? '';
    $row = $db->prepare("SELECT mt.staff_id FROM mobile_tokens mt JOIN staff s ON mt.staff_id = s.id WHERE mt.token = :t AND mt.expires_at > datetime('now') AND s.active = 1");
    $row->execute([':t' => $token]);
    $auth = $row->fetch();
    if (!$auth) {
        echo json_encode(['ok' => false, 'error' => 'Invalid token']);
        exit;
    }
    // Set session staff_id so existing my_dashboard logic works
    $_SESSION['staff_id'] = $auth['staff_id'];
    // Fall through to existing my_dashboard GET handler
    // (Or duplicate the logic here — depends on your api.php structure)
    // For simplicity, redirect to GET:
    $_GET['action'] = 'my_dashboard';
    // Re-run the GET switch... or just duplicate the query here.
    // Best approach: extract my_dashboard logic into a function and call it.
    break;
```

### 2.2 Add Token Auth for POST Task Operations

Add this helper function at the top of `api.php`:

```php
function authenticateMobileToken($db, $input) {
    $token = $input['mobile_token'] ?? '';
    if (empty($token)) return null;
    $stmt = $db->prepare("SELECT mt.staff_id, s.name, s.role FROM mobile_tokens mt JOIN staff s ON mt.staff_id = s.id WHERE mt.token = :t AND mt.expires_at > datetime('now') AND s.active = 1");
    $stmt->execute([':t' => $token]);
    return $stmt->fetch();
}
```

Then in the POST handler, before the session check, add:

```php
// Mobile token auth fallback
$mobileAuth = authenticateMobileToken($db, $input);
if ($mobileAuth) {
    $_SESSION['staff_id'] = $mobileAuth['staff_id'];
    $_SESSION['staff_name'] = $mobileAuth['name'];
    $_SESSION['staff_role'] = $mobileAuth['role'];
}
```

This lets mobile users pass `mobile_token` in any POST body to authenticate for `task_create`, `task_update`, `task_comment`, `task_delete`, `team_add`, `team_update`, `team_toggle`, `settings_update`.

### 2.3 Token Validation Endpoint

```php
case 'mobile_verify':
    $token = $input['token'] ?? '';
    $row = $db->prepare("SELECT mt.staff_id, s.name, s.role FROM mobile_tokens mt JOIN staff s ON mt.staff_id = s.id WHERE mt.token = :t AND mt.expires_at > datetime('now') AND s.active = 1");
    $row->execute([':t' => $token]);
    $auth = $row->fetch();
    if ($auth) {
        echo json_encode(['ok' => true, 'staff' => ['id' => $auth['staff_id'], 'name' => $auth['name'], 'role' => $auth['role']]]);
    } else {
        echo json_encode(['ok' => false, 'error' => 'Token expired or invalid']);
    }
    exit;

case 'mobile_logout':
    $token = $input['token'] ?? '';
    $db->prepare("DELETE FROM mobile_tokens WHERE token = :t")->execute([':t' => $token]);
    echo json_encode(['ok' => true]);
    exit;
```

---

## 3. Flutter Project Setup

### 3.1 Create Project

```bash
flutter create --org com.getlead --project-name getlead_hq getlead_hq
cd getlead_hq
```

### 3.2 `pubspec.yaml` Dependencies

```yaml
name: getlead_hq
description: Getlead HQ - Team ERP
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  google_fonts: ^6.1.0
  intl: ^0.19.0
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  pull_to_refresh_flutter3: ^2.0.2
  connectivity_plus: ^5.0.2
  cached_network_image: ^3.3.1
  pin_code_fields: ^8.0.1
  flutter_animate: ^4.3.0
  dropdown_search: ^5.0.6
  fluttertoast: ^8.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
```

### 3.3 Android Config

**`android/app/build.gradle`:**
```groovy
android {
    namespace "com.getlead.hq"
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.getlead.hq"
        minSdkVersion 23  // Android 6.0
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 3.4 iOS Config

**`ios/Runner/Info.plist`** — set `CFBundleDisplayName` to `Getlead HQ`, min iOS 13.0.

---

## 4. File Structure

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── constants.dart          # API URLs, color tokens, role maps
│   └── theme.dart              # ThemeData with Poppins, colors
│
├── models/
│   ├── staff.dart
│   ├── task.dart
│   ├── comment.dart
│   ├── history_entry.dart
│   ├── dashboard_stats.dart
│   ├── my_dashboard.dart
│   ├── daily_report.dart
│   └── report_field.dart
│
├── services/
│   ├── api_service.dart        # All HTTP calls via Dio
│   ├── auth_service.dart       # Login, logout, token management
│   └── cache_service.dart      # SharedPreferences caching
│
├── providers/
│   ├── auth_provider.dart
│   ├── tasks_provider.dart
│   ├── dashboard_provider.dart
│   ├── team_provider.dart
│   └── report_provider.dart
│
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart        # Shell with bottom nav
│   ├── admin_dashboard_screen.dart
│   ├── my_dashboard_screen.dart
│   ├── tasks_screen.dart
│   ├── task_detail_screen.dart
│   ├── create_task_screen.dart
│   ├── daily_report_screen.dart
│   ├── reports_view_screen.dart
│   ├── team_screen.dart
│   ├── team_edit_screen.dart
│   ├── settings_screen.dart
│   └── profile_screen.dart
│
├── widgets/
│   ├── kpi_card.dart
│   ├── task_card.dart
│   ├── status_badge.dart
│   ├── priority_dot.dart
│   ├── role_badge.dart
│   ├── skeleton_loader.dart
│   ├── empty_state.dart
│   ├── filter_bar.dart
│   ├── report_field_widget.dart
│   └── section_header.dart
```

---

## 5. Design System

### 🚫 CRITICAL: NO PURPLE ANYWHERE. Akhil hates purple. Never use purple, violet, indigo, or any purple-adjacent color.

### 5.1 Color Constants (`config/constants.dart`)

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Core
  static const background = Colors.white;
  static const foreground = Color(0xFF18181B);      // near-black hsl(240, 5.9%, 10%)
  static const primary = Color(0xFF18181B);          // same as foreground
  static const accent = Color(0xFF14B8A6);           // teal
  static const accentLight = Color(0xFFCCFBF1);     // teal-light

  // Neutral
  static const muted = Color(0xFFF4F4F5);           // hsl(240 4.8% 95.9%)
  static const mutedForeground = Color(0xFF71717A);  // zinc-500
  static const border = Color(0xFFE4E4E7);           // hsl(240 5.9% 90%)
  static const card = Colors.white;

  // Semantic
  static const destructive = Color(0xFFEF4444);      // red
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
```

### 5.2 Theme (`config/theme.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get light {
    final poppins = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: poppins.apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.destructive,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.foreground,
        outline: AppColors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.mutedForeground),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        selectedColor: AppColors.accentLight,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
```

---

## 6. Data Models

### 6.1 Staff (`models/staff.dart`)

```dart
class Staff {
  final int id;
  final String name;
  final String role;
  final String? telegramId;
  final bool active;
  final String? roleLabel;
  // Optional enriched fields from team_list
  final int? activeTasks;
  final String? lastReportDate;
  final String? lastLogin;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    this.telegramId,
    this.active = true,
    this.roleLabel,
    this.activeTasks,
    this.lastReportDate,
    this.lastLogin,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    telegramId: json['telegram_id'],
    active: json['active'] == 1 || json['active'] == true,
    roleLabel: json['role_label'],
    activeTasks: json['active_tasks'] != null ? int.tryParse(json['active_tasks'].toString()) : null,
    lastReportDate: json['last_report_date'],
    lastLogin: json['last_login'],
  );

  String get emoji => AppConstants.roleEmojis[role] ?? '👤';
  String get label => roleLabel ?? AppConstants.roleLabels[role] ?? role;
}
```

### 6.2 Task (`models/task.dart`)

```dart
class Task {
  final int id;
  final String title;
  final String? description;
  final int? assignedTo;
  final int? createdBy;
  final String priority; // urgent, high, normal, low
  final String status;   // pending, in_progress, done, blocked
  final String? dueDate;
  final String? completedAt;
  final String? notes;
  final String? category;
  final String createdAt;
  final String updatedAt;
  final String? assigneeName;
  final String? assigneeRole;
  final String? creatorName;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.createdBy,
    this.priority = 'normal',
    this.status = 'pending',
    this.dueDate,
    this.completedAt,
    this.notes,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeName,
    this.assigneeRole,
    this.creatorName,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: int.parse(json['id'].toString()),
    title: json['title'] ?? '',
    description: json['description'],
    assignedTo: json['assigned_to'] != null ? int.tryParse(json['assigned_to'].toString()) : null,
    createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
    priority: json['priority'] ?? 'normal',
    status: json['status'] ?? 'pending',
    dueDate: json['due_date'],
    completedAt: json['completed_at'],
    notes: json['notes'],
    category: json['category'],
    createdAt: json['created_at'] ?? '',
    updatedAt: json['updated_at'] ?? '',
    assigneeName: json['assignee_name'],
    assigneeRole: json['assignee_role'],
    creatorName: json['creator_name'],
  );

  bool get isOverdue {
    if (dueDate == null || status == 'done') return false;
    return DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) ?? false;
  }

  String get categoryEmoji => AppConstants.categoryEmojis[category] ?? '📌';
}
```

### 6.3 Comment (`models/comment.dart`)

```dart
class Comment {
  final int id;
  final int taskId;
  final int staffId;
  final String comment;
  final String createdAt;
  final String? staffName;
  final String? staffRole;

  Comment({required this.id, required this.taskId, required this.staffId,
    required this.comment, required this.createdAt, this.staffName, this.staffRole});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: int.parse(json['id'].toString()),
    taskId: int.parse(json['task_id'].toString()),
    staffId: int.parse(json['staff_id'].toString()),
    comment: json['comment'] ?? '',
    createdAt: json['created_at'] ?? '',
    staffName: json['staff_name'],
    staffRole: json['staff_role'],
  );
}
```

### 6.4 History Entry (`models/history_entry.dart`)

```dart
class HistoryEntry {
  final int id;
  final int taskId;
  final int staffId;
  final String action; // created, status_changed, assigned, commented, updated, deleted
  final String? oldValue;
  final String? newValue;
  final String createdAt;
  final String? staffName;

  HistoryEntry({required this.id, required this.taskId, required this.staffId,
    required this.action, this.oldValue, this.newValue, required this.createdAt, this.staffName});

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: int.parse(json['id'].toString()),
    taskId: int.parse(json['task_id'].toString()),
    staffId: int.parse(json['staff_id'].toString()),
    action: json['action'] ?? '',
    oldValue: json['old_value'],
    newValue: json['new_value'],
    createdAt: json['created_at'] ?? '',
    staffName: json['staff_name'],
  );

  String get description => switch (action) {
    'created' => '${staffName ?? 'Someone'} created this task',
    'status_changed' => '${staffName ?? 'Someone'} changed status from $oldValue to $newValue',
    'assigned' => '${staffName ?? 'Someone'} assigned to $newValue',
    'commented' => '${staffName ?? 'Someone'} added a comment',
    'updated' => '${staffName ?? 'Someone'} updated the task',
    'deleted' => '${staffName ?? 'Someone'} deleted the task',
    _ => '${staffName ?? 'Someone'} performed $action',
  };
}
```

### 6.5 Dashboard Stats (`models/dashboard_stats.dart`)

```dart
class DashboardStats {
  final int totalStaff;
  final int totalTasks;
  final int overdueTasks;
  final int completedToday;
  final int reportsSubmitted;
  final String reportRate;
  final String weekCompletion;
  final List<dynamic> recentActivity;
  final List<dynamic> teamStatus;
  final List<dynamic> reportsMissing;
  final List<dynamic> reportsSubmittedList;

  DashboardStats({
    required this.totalStaff, required this.totalTasks, required this.overdueTasks,
    required this.completedToday, required this.reportsSubmitted, required this.reportRate,
    required this.weekCompletion, required this.recentActivity, required this.teamStatus,
    required this.reportsMissing, required this.reportsSubmittedList,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalStaff: int.tryParse(json['total_staff'].toString()) ?? 0,
    totalTasks: int.tryParse(json['total_tasks'].toString()) ?? 0,
    overdueTasks: int.tryParse(json['overdue_tasks'].toString()) ?? 0,
    completedToday: int.tryParse(json['completed_today'].toString()) ?? 0,
    reportsSubmitted: int.tryParse(json['reports_submitted'].toString()) ?? 0,
    reportRate: json['report_rate']?.toString() ?? '0%',
    weekCompletion: json['week_completion']?.toString() ?? '0%',
    recentActivity: json['recent_activity'] ?? [],
    teamStatus: json['team_status'] ?? [],
    reportsMissing: json['reports_missing'] ?? [],
    reportsSubmittedList: json['reports_submitted_list'] ?? [],
  );
}
```

### 6.6 My Dashboard (`models/my_dashboard.dart`)

```dart
class MyDashboard {
  final int tasksOpen;
  final int tasksCompletedMonth;
  final int tasksOverdue;
  final String completionRate;
  final int tasksCompletedWeek;
  final int reportStreak;
  final String? lastReportDate;
  final List<dynamic> reportCalendar; // [{date, submitted}]
  final String avgCompletionDays;
  final bool reportedToday;

  MyDashboard({
    required this.tasksOpen, required this.tasksCompletedMonth, required this.tasksOverdue,
    required this.completionRate, required this.tasksCompletedWeek, required this.reportStreak,
    this.lastReportDate, required this.reportCalendar, required this.avgCompletionDays,
    required this.reportedToday,
  });

  factory MyDashboard.fromJson(Map<String, dynamic> json) => MyDashboard(
    tasksOpen: int.tryParse(json['tasks_open'].toString()) ?? 0,
    tasksCompletedMonth: int.tryParse(json['tasks_completed_month'].toString()) ?? 0,
    tasksOverdue: int.tryParse(json['tasks_overdue'].toString()) ?? 0,
    completionRate: json['completion_rate']?.toString() ?? '0%',
    tasksCompletedWeek: int.tryParse(json['tasks_completed_week'].toString()) ?? 0,
    reportStreak: int.tryParse(json['report_streak'].toString()) ?? 0,
    lastReportDate: json['last_report_date'],
    reportCalendar: json['report_calendar'] ?? [],
    avgCompletionDays: json['avg_completion_days']?.toString() ?? '0',
    reportedToday: json['reported_today'] == true || json['reported_today'] == 1,
  );
}
```

### 6.7 Report Field Definition (`models/report_field.dart`)

```dart
enum FieldType { number, text, paymentArray }

class ReportField {
  final String key;
  final String label;
  final FieldType type;
  final String emoji;
  final bool required;
  final String? hint;

  const ReportField({
    required this.key,
    required this.label,
    required this.type,
    required this.emoji,
    this.required = false,
    this.hint,
  });
}

// Role-specific report field definitions
const Map<String, List<ReportField>> roleReportFields = {
  'sales_rep': [
    ReportField(key: 'calls_made', label: 'Calls Made', type: FieldType.number, emoji: '📞', required: true),
    ReportField(key: 'calls_connected', label: 'Calls Connected', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'demos_scheduled', label: 'Demos Scheduled', type: FieldType.number, emoji: '📅'),
    ReportField(key: 'demos_completed', label: 'Demos Completed', type: FieldType.number, emoji: '🎯'),
    ReportField(key: 'trials', label: 'Trials Started', type: FieldType.number, emoji: '🧪'),
    ReportField(key: 'payments_closed', label: 'Payments Closed', type: FieldType.number, emoji: '💰'),
    ReportField(key: 'payments_amount', label: 'Payment Amount (₹)', type: FieldType.number, emoji: '💵'),
    ReportField(key: 'hot_leads', label: 'Hot Leads', type: FieldType.text, emoji: '🔥', hint: 'List promising leads...'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝', hint: 'Any additional notes...'),
  ],
  'secretary': [
    ReportField(key: 'payments', label: 'Payments Received', type: FieldType.paymentArray, emoji: '💳', required: true),
    ReportField(key: 'tickets_handled', label: 'Tickets Handled', type: FieldType.number, emoji: '🎫'),
    ReportField(key: 'license_updates', label: 'License Updates', type: FieldType.number, emoji: '📄'),
    ReportField(key: 'followups', label: 'Follow-ups Done', type: FieldType.number, emoji: '📞'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'support': [
    ReportField(key: 'tickets_handled', label: 'Tickets Handled', type: FieldType.number, emoji: '🎫', required: true),
    ReportField(key: 'tickets_resolved', label: 'Tickets Resolved', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'avg_response_time', label: 'Avg Response Time (min)', type: FieldType.number, emoji: '⏱️'),
    ReportField(key: 'escalation_count', label: 'Escalations', type: FieldType.number, emoji: '⬆️'),
    ReportField(key: 'escalation_details', label: 'Escalation Details', type: FieldType.text, emoji: '📋'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'hr': [
    ReportField(key: 'attendance', label: 'Attendance Summary', type: FieldType.text, emoji: '📊', required: true),
    ReportField(key: 'leave_requests', label: 'Leave Requests', type: FieldType.number, emoji: '🏖️'),
    ReportField(key: 'interviews', label: 'Interviews Conducted', type: FieldType.number, emoji: '🤝'),
    ReportField(key: 'issues', label: 'HR Issues', type: FieldType.text, emoji: '⚠️'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'finance': [
    ReportField(key: 'invoices', label: 'Invoices Generated', type: FieldType.number, emoji: '🧾', required: true),
    ReportField(key: 'collected_count', label: 'Payments Collected', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'collected_amount', label: 'Collected Amount (₹)', type: FieldType.number, emoji: '💵'),
    ReportField(key: 'pending_count', label: 'Pending Payments', type: FieldType.number, emoji: '⏳'),
    ReportField(key: 'pending_amount', label: 'Pending Amount (₹)', type: FieldType.number, emoji: '💸'),
    ReportField(key: 'expenses_count', label: 'Expenses Logged', type: FieldType.number, emoji: '📤'),
    ReportField(key: 'expenses_amount', label: 'Expenses Amount (₹)', type: FieldType.number, emoji: '💰'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'developer': [
    ReportField(key: 'tasks', label: 'Tasks Worked On', type: FieldType.text, emoji: '💻', required: true, hint: 'What did you work on today?'),
    ReportField(key: 'commits', label: 'Commits Made', type: FieldType.number, emoji: '📦'),
    ReportField(key: 'bugs_fixed', label: 'Bugs Fixed', type: FieldType.number, emoji: '🐛'),
    ReportField(key: 'blockers', label: 'Blockers', type: FieldType.text, emoji: '🚧', hint: 'Any blockers?'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'tester': [
    ReportField(key: 'test_cases', label: 'Test Cases Run', type: FieldType.number, emoji: '🧪', required: true),
    ReportField(key: 'bugs_found', label: 'Bugs Found', type: FieldType.number, emoji: '🐛'),
    ReportField(key: 'bugs_verified', label: 'Bugs Verified', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'blockers', label: 'Blockers', type: FieldType.text, emoji: '🚧'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'admin': [
    ReportField(key: 'tasks', label: 'Tasks & Activities', type: FieldType.text, emoji: '⚡', required: true, hint: 'What did you work on today?'),
    ReportField(key: 'decisions', label: 'Key Decisions', type: FieldType.text, emoji: '🎯', hint: 'Important decisions made...'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
};
```

---

## 7. API Service

### `services/api_service.dart`

```dart
import 'package:dio/dio.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  String? _mobileToken;
  void setToken(String? token) => _mobileToken = token;

  // ========== GET REQUESTS (use api_token query param) ==========

  Future<Map<String, dynamic>> _get(String action, [Map<String, String>? params]) async {
    final queryParams = {
      'action': action,
      'api_token': AppConstants.apiToken,
      ...?params,
    };
    final response = await _dio.get('', queryParameters: queryParams);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  /// Fetch staff list
  Future<List<Staff>> getStaff() async {
    final data = await _get('staff');
    return (data['staff'] as List? ?? []).map((e) => Staff.fromJson(e)).toList();
  }

  /// Fetch tasks with optional filters
  Future<({List<Task> tasks, int total, int pages})> getTasks({
    int? assignedTo,
    String? status,
    String? priority,
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (assignedTo != null) params['assigned_to'] = assignedTo.toString();
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _get('tasks', params);
    final tasks = (data['tasks'] as List? ?? []).map((e) => Task.fromJson(e)).toList();
    return (tasks: tasks, total: int.tryParse(data['total'].toString()) ?? 0, pages: int.tryParse(data['pages'].toString()) ?? 1);
  }

  /// Fetch single task detail
  Future<({Task task, List<Comment> comments, List<HistoryEntry> history})> getTaskDetail(int taskId) async {
    final data = await _get('task_detail', {'task_id': taskId.toString()});
    return (
      task: Task.fromJson(data['task']),
      comments: (data['comments'] as List? ?? []).map((e) => Comment.fromJson(e)).toList(),
      history: (data['history'] as List? ?? []).map((e) => HistoryEntry.fromJson(e)).toList(),
    );
  }

  /// Admin dashboard stats
  Future<DashboardStats> getDashboardStats() async {
    final data = await _get('dashboard_stats');
    return DashboardStats.fromJson(data);
  }

  /// Team list (enriched)
  Future<List<Staff>> getTeamList() async {
    final data = await _get('team_list');
    return (data['staff'] as List? ?? []).map((e) => Staff.fromJson(e)).toList();
  }

  /// Summary for a date
  Future<Map<String, dynamic>> getSummary(String date) async {
    return await _get('summary', {'date': date});
  }

  /// Today's reports
  Future<Map<String, dynamic>> getToday() async => await _get('today');

  /// Missing reports
  Future<List<dynamic>> getMissing() async {
    final data = await _get('missing');
    return data['missing'] ?? data['staff'] ?? [];
  }

  // ========== POST REQUESTS (use mobile_token) ==========

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (_mobileToken != null) {
      body['mobile_token'] = _mobileToken;
    }
    final response = await _dio.post('', data: body);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  /// Mobile login
  Future<Map<String, dynamic>> mobileLogin(int staffId, String pin) async {
    final response = await _dio.post('', data: {
      'action': 'mobile_login',
      'staff_id': staffId,
      'pin': pin,
    });
    return response.data;
  }

  /// Verify token
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _dio.post('', data: {
      'action': 'mobile_verify',
      'token': token,
    });
    return response.data;
  }

  /// Logout
  Future<void> mobileLogout(String token) async {
    await _dio.post('', data: {'action': 'mobile_logout', 'token': token});
  }

  /// My dashboard (via mobile token)
  Future<MyDashboard> getMyDashboard() async {
    final data = await _post({'action': 'mobile_my_dashboard', 'token': _mobileToken});
    return MyDashboard.fromJson(data);
  }

  /// Create task
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    required List<int> assignees,
    String priority = 'normal',
    String? dueDate,
    String? category,
  }) async {
    return await _post({
      'action': 'task_create',
      'title': title,
      'description': description ?? '',
      'assignees': assignees,
      'priority': priority,
      'due_date': dueDate,
      'category': category,
    });
  }

  /// Update task
  Future<Map<String, dynamic>> updateTask(int taskId, Map<String, dynamic> updates) async {
    return await _post({
      'action': 'task_update',
      'task_id': taskId,
      ...updates,
    });
  }

  /// Add comment
  Future<Map<String, dynamic>> addComment(int taskId, String comment) async {
    return await _post({
      'action': 'task_comment',
      'task_id': taskId,
      'comment': comment,
    });
  }

  /// Delete task (admin only)
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    return await _post({'action': 'task_delete', 'task_id': taskId});
  }

  /// Submit daily report
  Future<Map<String, dynamic>> submitReport(String date, Map<String, dynamic> data) async {
    final response = await _dio.post('', data: {
      'action': 'mobile_submit_report',
      'token': _mobileToken,
      'date': date,
      'data': data,
    });
    return response.data;
  }

  /// Team management
  Future<Map<String, dynamic>> addTeamMember(Map<String, dynamic> data) async {
    return await _post({...data, 'action': 'team_add'});
  }

  Future<Map<String, dynamic>> updateTeamMember(Map<String, dynamic> data) async {
    return await _post({...data, 'action': 'team_update'});
  }

  Future<Map<String, dynamic>> toggleTeamMember(int id) async {
    return await _post({'action': 'team_toggle', 'id': id});
  }

  /// Settings
  Future<Map<String, dynamic>> updateSetting(String key, dynamic value) async {
    return await _post({'action': 'settings_update', 'key': key, 'value': value});
  }
}
```

---

## 8. Auth Flow

### `services/auth_service.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'mobile_token';
  static const _staffIdKey = 'staff_id';
  static const _staffNameKey = 'staff_name';
  static const _staffRoleKey = 'staff_role';

  final ApiService _api = ApiService();

  Future<({bool ok, String? error, Map<String, dynamic>? staff})> login(int staffId, String pin) async {
    try {
      final result = await _api.mobileLogin(staffId, pin);
      if (result['ok'] == true) {
        final token = result['token'] as String;
        final staff = result['staff'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setInt(_staffIdKey, staff['id']);
        await prefs.setString(_staffNameKey, staff['name']);
        await prefs.setString(_staffRoleKey, staff['role']);
        _api.setToken(token);
        return (ok: true, error: null, staff: staff);
      }
      return (ok: false, error: result['error'] ?? 'Login failed', staff: null);
    } catch (e) {
      return (ok: false, error: 'Network error: $e', staff: null);
    }
  }

  Future<({bool loggedIn, int? staffId, String? name, String? role})> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return (loggedIn: false, staffId: null, name: null, role: null);

    try {
      final result = await _api.verifyToken(token);
      if (result['ok'] == true) {
        _api.setToken(token);
        final staff = result['staff'];
        return (loggedIn: true, staffId: staff['id'], name: staff['name'], role: staff['role']);
      }
    } catch (_) {
      // Token might still be valid, use cached data
      final id = prefs.getInt(_staffIdKey);
      final name = prefs.getString(_staffNameKey);
      final role = prefs.getString(_staffRoleKey);
      if (id != null) {
        _api.setToken(token);
        return (loggedIn: true, staffId: id, name: name, role: role);
      }
    }
    return (loggedIn: false, staffId: null, name: null, role: null);
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
```

### Auth Flow Summary

1. **App starts** → Check `SharedPreferences` for saved token
2. **Token found** → Call `mobile_verify` to validate. If valid, go to Home. If invalid, go to Login.
3. **No token** → Show Login screen
4. **Login screen** → Fetch staff list from `?action=staff` (GET, uses api_token). User selects name, enters 4-digit PIN. Call `mobile_login` (POST). On success, save token + staff info to SharedPreferences.
5. **All subsequent POST requests** → Include `mobile_token` in body for auth.
6. **Logout** → Call `mobile_logout`, clear SharedPreferences.

---

## 9. Screens — Detailed Specs

### 9.1 Login Screen (`screens/login_screen.dart`)

**Layout:**
```
[SafeArea, white background, centered content]
├── Spacer
├── Logo: Row(
│     Text("Getlead", style: Poppins Bold 28, color: foreground),
│     Text(" HQ", style: Poppins Bold 28, color: teal),
│   )
├── SizedBox(24)
├── Container(white card, border, rounded 16, padding 24)
│   ├── Text("Sign in to continue", muted foreground, 14)
│   ├── SizedBox(20)
│   ├── DropdownSearch<Staff>(
│   │     label: "Select your name",
│   │     items: staffList,
│   │     displayItem: (s) => "${roleEmojis[s.role]} ${s.name}",
│   │     onChanged: setSelectedStaff,
│   │   )
│   ├── SizedBox(16)
│   ├── PinCodeTextField(
│   │     length: 4,
│   │     obscureText: true,
│   │     keyboardType: number,
│   │     pinTheme: PinTheme(
│   │       shape: BoxShape.roundedRectangle,
│   │       fieldWidth: 56, fieldHeight: 56,
│   │       activeFillColor: muted, inactiveFillColor: muted,
│   │       selectedFillColor: accentLight,
│   │       borderRadius: 8,
│   │       activeColor: accent, selectedColor: accent, inactiveColor: border,
│   │     ),
│   │   )
│   ├── SizedBox(20)
│   ├── SizedBox(width: double.infinity, child:
│   │     ElevatedButton("Sign In", onPressed: _login, height: 48)
│   │   )
│   └── if (error) Text(error, color: destructive)
├── Spacer
└── Text("Getlead Analytics Pvt Ltd", muted foreground, 12)
```

**Behavior:**
- On mount: fetch `ApiService().getStaff()` → filter active only → populate dropdown
- Show shimmer while loading staff list
- PIN field auto-focuses after staff selection
- On submit: show loading indicator on button, call login
- On success: Navigate to HomeScreen, replace route
- On error: Show error text below button, shake animation

### 9.2 Home Screen / Shell (`screens/home_screen.dart`)

**Layout:**
```
Scaffold(
  body: IndexedStack(children: [
    isAdmin ? AdminDashboardScreen : MyDashboardScreen,
    TasksScreen,
    DailyReportScreen,
    isAdmin ? TeamScreen : ProfileScreen,
    isAdmin ? SettingsScreen : ProfileScreen,  // or ReportsViewScreen for admin
  ]),
  bottomNavigationBar: BottomNavigationBar(items: [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
    BottomNavigationBarItem(icon: Icon(Icons.edit_note_rounded), label: 'Report'),
    isAdmin
      ? BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Team')
      : BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
    isAdmin
      ? BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings')
      : BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ]),
)
```

### 9.3 Admin Dashboard (`screens/admin_dashboard_screen.dart`)

**Layout:**
```
RefreshIndicator(
  child: ListView(
    padding: 16,
    children: [
      // Greeting
      Text("Welcome back, $name 👋", Poppins SemiBold 22)
      Text(formattedDate, muted foreground, 14)
      SizedBox(20)

      // KPI Grid (2x2)
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: Never,
        children: [
          KpiCard(label: "Total Tasks", value: stats.totalTasks, icon: Icons.task, color: blue),
          KpiCard(label: "Overdue", value: stats.overdueTasks, icon: Icons.warning, color: destructive),
          KpiCard(label: "Done Today", value: stats.completedToday, icon: Icons.check_circle, color: green),
          KpiCard(label: "Report Rate", value: stats.reportRate, icon: Icons.assessment, color: teal),
        ]
      )
      SizedBox(20)

      // Reports Missing Alert
      if (stats.reportsMissing.isNotEmpty)
        Container(padding: 16, decoration: BoxDecoration(color: Color(0xFFFEF3C7), borderRadius: 12),
          child: Column([
            Row([Icon(Icons.warning_amber, amber), Text("Reports Missing", SemiBold)]),
            ...stats.reportsMissing.map((s) => Text("${roleEmojis[s.role]} ${s.name}")),
          ])
        )
      SizedBox(16)

      // Team Status
      SectionHeader("Team Status")
      ...stats.teamStatus.map((member) =>
        ListTile(
          leading: CircleAvatar(child: Text(roleEmojis[member.role])),
          title: Text(member.name),
          subtitle: Text("${member.pending_tasks} pending • ${member.overdue_tasks} overdue"),
          trailing: Text(member.last_report ?? 'No report', muted),
        )
      )
      SizedBox(16)

      // Recent Activity
      SectionHeader("Recent Activity")
      ...stats.recentActivity.take(10).map((a) =>
        ListTile(
          leading: Icon(activityIcon(a['action']), size: 20),
          title: Text(a['description'] ?? a['action'], 13),
          subtitle: Text(timeAgo(a['created_at']), 11, muted),
        )
      )
    ]
  )
)
```

**API Call:** `ApiService().getDashboardStats()` on mount and pull-to-refresh.

### 9.4 My Dashboard (`screens/my_dashboard_screen.dart`)

**Layout:**
```
RefreshIndicator(
  child: ListView(padding: 16, children: [
    // Greeting
    Text("Hey, $name 👋", Poppins SemiBold 22)
    Text(formattedDate, muted, 14)
    SizedBox(20)

    // KPI Grid (2x2)
    GridView.count(crossAxisCount: 2, shrinkWrap: true,
      children: [
        KpiCard(label: "Tasks Open", value: dash.tasksOpen, icon: Icons.inbox, color: blue),
        KpiCard(label: "Done This Month", value: dash.tasksCompletedMonth, icon: Icons.check, color: green),
        KpiCard(label: "Overdue", value: dash.tasksOverdue, icon: Icons.warning, color: destructive),
        KpiCard(label: "Completion", value: dash.completionRate, icon: Icons.speed, color: teal),
      ]
    )
    SizedBox(20)

    // Report Streak Card
    Container(padding: 16, decoration: BoxDecoration(border, rounded 12),
      child: Column([
        Row([Text("🔥 Report Streak"), Text("${dash.reportStreak} days", teal, Bold)]),
        SizedBox(12),
        // Calendar dots row (last 14 days)
        Row(mainAxisAlignment: spaceEvenly,
          children: last14Days.map((day) =>
            Column([
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: circle,
                  color: day.submitted ? green : border,
                ),
              ),
              Text(day.dayLabel, 9, muted),  // "M", "T", "W"...
            ])
          ).toList(),
        )
      ])
    )
    SizedBox(16)

    // Quick Stats
    Row(spaceEvenly, [
      _StatChip("Last Report", dash.lastReportDate ?? 'Never'),
      _StatChip("This Week", "${dash.tasksCompletedWeek}"),
      _StatChip("Avg Days", dash.avgCompletionDays),
    ])

    // Report today nudge
    if (!dash.reportedToday)
      Container(margin: top 16, padding: 16, decoration: BoxDecoration(accentLight, rounded 12),
        child: Row([
          Text("✏️ "),
          Expanded(Text("You haven't submitted today's report yet")),
          TextButton("Submit", onPressed: () => switchToReportTab()),
        ])
      )
  ])
)
```

**API Call:** `ApiService().getMyDashboard()` — uses mobile token.

### 9.5 Tasks Screen (`screens/tasks_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(
    title: Text("Tasks"),
    actions: [
      if (isAdmin) ToggleButtons(["My Tasks", "All Tasks"], selected: viewMode)
    ],
  ),
  body: Column([
    // Filter bar
    Container(padding: EdgeInsets.symmetric(h:16, v:8),
      child: Column([
        // Search
        TextField(
          decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Search tasks..."),
          onChanged: debounce(search),
        ),
        SizedBox(8),
        // Filter chips row (horizontally scrollable)
        SingleChildScrollView(scrollDirection: horizontal,
          child: Row([
            FilterChip(label: "All", selected: statusFilter == null),
            FilterChip(label: "Pending", selected: statusFilter == 'pending'),
            FilterChip(label: "In Progress", selected: statusFilter == 'in_progress'),
            FilterChip(label: "Blocked", selected: statusFilter == 'blocked'),
            FilterChip(label: "Done", selected: statusFilter == 'done'),
          ])
        ),
        if (isAdmin && viewMode == 'all')
          // Priority filter row
          SingleChildScrollView(scrollDirection: horizontal,
            child: Row([
              FilterChip(label: "All Priorities", selected: priorityFilter == null),
              FilterChip(label: "🔴 Urgent", selected: priorityFilter == 'urgent'),
              FilterChip(label: "🟡 High", selected: priorityFilter == 'high'),
              FilterChip(label: "🔵 Normal", selected: priorityFilter == 'normal'),
              FilterChip(label: "⚪ Low", selected: priorityFilter == 'low'),
            ])
          ),
      ])
    ),
    // Task list
    Expanded(
      child: RefreshIndicator(
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) => TaskCard(
            task: tasks[i],
            showAssignee: isAdmin && viewMode == 'all',
            onDone: () => _markDone(tasks[i]),
            onTap: () => _openDetail(tasks[i]),
          ),
        ),
      ),
    ),
  ]),
  floatingActionButton: (isAdmin)
    ? FloatingActionButton(
        onPressed: () => Navigator.push(context, CreateTaskScreen()),
        child: Icon(Icons.add),
      )
    : null,
)
```

**API Call:** `ApiService().getTasks(...)` with filters. For staff: always pass `assignedTo: currentStaffId`. For admin "My Tasks": same. For admin "All Tasks": no assignedTo filter.

**Pagination:** Load more on scroll to bottom. Use `page` parameter.

### 9.6 Task Card Widget (`widgets/task_card.dart`)

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: start, children: [
          Row(children: [
            // Priority dot
            Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: circle, color: priorityColor(task.priority))),
            SizedBox(width: 8),
            // Title
            Expanded(child: Text(task.title, style: TextStyle(fontWeight: w500, fontSize: 15))),
            // Status badge
            StatusBadge(task.status),
          ]),
          SizedBox(height: 8),
          Row(children: [
            if (showAssignee && task.assigneeName != null) ...[
              Icon(Icons.person, size: 14, color: muted),
              SizedBox(width: 4),
              Text(task.assigneeName!, style: TextStyle(fontSize: 12, color: muted)),
              SizedBox(width: 12),
            ],
            if (task.dueDate != null) ...[
              Icon(Icons.calendar_today, size: 14,
                color: task.isOverdue ? destructive : muted),
              SizedBox(width: 4),
              Text(formatDate(task.dueDate!),
                style: TextStyle(fontSize: 12,
                  color: task.isOverdue ? destructive : muted)),
            ],
            Spacer(),
            Text(task.categoryEmoji, style: TextStyle(fontSize: 14)),
          ]),
          if (task.status != 'done')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDone,
                icon: Icon(Icons.check, size: 16, color: green),
                label: Text("Done", style: TextStyle(color: green, fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(60, 30)),
              ),
            ),
        ]),
      ),
    ),
  ),
)
```

### 9.7 Task Detail (`screens/task_detail_screen.dart`)

Open as a **full-screen page** (or bottom sheet for quick view).

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("Task Detail")),
  body: RefreshIndicator(
    child: ListView(padding: 16, children: [
      // Title
      Text(task.title, style: Poppins SemiBold 20)
      SizedBox(8)

      // Badges row
      Wrap(spacing: 8, children: [
        StatusBadge(task.status),
        PriorityBadge(task.priority),
        CategoryBadge(task.category),
      ])
      SizedBox(16)

      // Description
      if (task.description?.isNotEmpty == true)
        Text(task.description!, style: TextStyle(fontSize: 14, height: 1.5))
      SizedBox(16)

      // Meta info
      _MetaRow(icon: Icons.calendar_today, label: "Due", value: task.dueDate ?? 'No due date')
      _MetaRow(icon: Icons.person, label: "Created by", value: task.creatorName ?? 'Unknown')
      _MetaRow(icon: Icons.access_time, label: "Created", value: timeAgo(task.createdAt))
      if (task.assigneeName != null)
        _MetaRow(icon: Icons.person_pin, label: "Assigned to", value: task.assigneeName!)
      SizedBox(16)

      // Editable fields (admin or assignee)
      if (canEdit) ...[
        Divider()
        SizedBox(8)
        // Status dropdown
        DropdownButtonFormField(label: "Status", value: task.status,
          items: ['pending', 'in_progress', 'done', 'blocked'])
        SizedBox(8)
        // Priority dropdown (admin only)
        if (isAdmin) DropdownButtonFormField(label: "Priority", value: task.priority,
          items: ['urgent', 'high', 'normal', 'low'])
        SizedBox(8)
        // Assignee dropdown (admin only)
        if (isAdmin) DropdownButtonFormField(label: "Assign to", value: task.assignedTo,
          items: staffList)
        SizedBox(16)
      ]

      // Comments section
      Divider()
      SectionHeader("Comments (${comments.length})")
      ...comments.map((c) =>
        Container(margin: bottom 8, padding: 12, decoration: BoxDecoration(muted, rounded 8),
          child: Column(crossAxisAlignment: start, [
            Row([
              Text("${roleEmojis[c.staffRole]} ${c.staffName}", SemiBold 13),
              Spacer(),
              Text(timeAgo(c.createdAt), 11, muted),
            ]),
            SizedBox(4),
            Text(c.comment, 14),
          ])
        )
      )
      // Add comment
      Row([
        Expanded(TextField(controller: commentController, hint: "Add a comment...")),
        IconButton(Icons.send, onPressed: _addComment),
      ])
      SizedBox(16)

      // History timeline
      Divider()
      SectionHeader("History")
      ...history.map((h) =>
        ListTile(
          leading: Container(width: 2, color: border),
          title: Text(h.description, 13),
          subtitle: Text(timeAgo(h.createdAt), 11, muted),
          dense: true,
        )
      )
    ])
  ),
  // Bottom action button
  bottomNavigationBar: (task.status != 'done')
    ? SafeArea(child: Padding(padding: 16,
        child: ElevatedButton.icon(
          onPressed: _markComplete,
          icon: Icon(Icons.check_circle),
          label: Text("Mark as Complete"),
          style: ElevatedButton.styleFrom(backgroundColor: green, minimumSize: Size(double.infinity, 48)),
        )
      ))
    : null,
)
```

**"Mark as Complete" behavior:**
1. Show dialog: "Add a completion note? (optional)"
2. TextField for note
3. On confirm: call `ApiService().updateTask(taskId, {'status': 'done'})`. If note provided, also call `addComment(taskId, "✅ Completed: $note")`.

### 9.8 Create Task (`screens/create_task_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("New Task")),
  body: Form(
    child: ListView(padding: 16, children: [
      // Title
      TextFormField(label: "Title *", validator: required)
      SizedBox(16)

      // Description
      TextFormField(label: "Description", maxLines: 4)
      SizedBox(16)

      // Assign to (admin only, multi-select chips)
      if (isAdmin) ...[
        Text("Assign to", style: SemiBold 14)
        SizedBox(8)
        Wrap(spacing: 8, runSpacing: 8,
          children: staffList.map((s) =>
            FilterChip(
              label: Text("${s.emoji} ${s.name}"),
              selected: selectedAssignees.contains(s.id),
              onSelected: (v) => toggle(s.id),
              selectedColor: accentLight,
              checkmarkColor: accent,
            )
          ).toList()
        )
        SizedBox(16)
      ]

      // Priority
      Text("Priority", SemiBold 14)
      SizedBox(8)
      SegmentedButton(segments: [
        ButtonSegment(value: 'low', label: Text("Low")),
        ButtonSegment(value: 'normal', label: Text("Normal")),
        ButtonSegment(value: 'high', label: Text("High")),
        ButtonSegment(value: 'urgent', label: Text("Urgent")),
      ], selected: {priority})
      SizedBox(16)

      // Due date
      ListTile(
        leading: Icon(Icons.calendar_today),
        title: Text(dueDate ?? "Select due date"),
        trailing: Icon(Icons.chevron_right),
        onTap: () => showDatePicker(...),
        shape: RoundedRectangleBorder(border, rounded 8),
      )
      SizedBox(16)

      // Category
      DropdownButtonFormField(label: "Category",
        items: ['sales', 'development', 'support', 'hr', 'finance', 'operations', 'other']
          .map((c) => DropdownMenuItem(value: c, child: Text("${categoryEmojis[c]} ${c.capitalize()}")))
      )
      SizedBox(24)

      // Submit
      ElevatedButton("Create Task", onPressed: _submit, minimumSize: Size(inf, 48))
    ])
  )
)
```

**API Call:** `ApiService().createTask(...)`. On success, pop back and refresh tasks list.

### 9.9 Daily Report (`screens/daily_report_screen.dart`)

**This is a wizard/stepper flow. One field per step with big emoji, progress bar.**

**Layout:**
```
Scaffold(
  appBar: AppBar(
    title: Text("Daily Report"),
    bottom: PreferredSize(
      child: LinearProgressIndicator(
        value: (currentStep + 1) / totalSteps,
        backgroundColor: muted,
        color: accent,
      ),
    ),
  ),
  body: PageView(
    controller: pageController,
    physics: NeverScrollableScrollPhysics(),  // controlled by buttons only
    children: [
      // Step 0: Date picker
      _DateStep(),
      // Steps 1-N: One per report field
      ...roleReportFields[currentRole]!.map((field) => _FieldStep(field)),
      // Final step: Review & Submit
      _ReviewStep(),
    ],
  ),
  bottomNavigationBar: SafeArea(
    child: Padding(padding: 16,
      child: Row(children: [
        if (currentStep > 0)
          OutlinedButton("Back", onPressed: _prevStep),
        Spacer(),
        if (currentStep < totalSteps - 1)
          ElevatedButton("Next", onPressed: _nextStep),
        if (currentStep == totalSteps - 1)
          ElevatedButton.icon(
            icon: Icon(Icons.send),
            label: Text("Submit"),
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: green),
          ),
      ])
    )
  ),
)
```

**Date Step:**
```
Center(child: Column(mainAxisAlignment: center, children: [
  Text("📅", style: TextStyle(fontSize: 48)),
  SizedBox(16),
  Text("Select Date", Poppins SemiBold 20),
  SizedBox(8),
  Text("Choose the date for your report", muted, 14),
  SizedBox(24),
  // Date picker button showing selected date
  OutlinedButton.icon(
    icon: Icon(Icons.calendar_today),
    label: Text(formattedDate, SemiBold 16),
    onPressed: () => showDatePicker(..., lastDate: DateTime.now()),
  ),
  SizedBox(8),
  if (existingReport) Text("⚠️ You already submitted for this date. This will update it.", amber, 12),
]))
```

**Number Field Step:**
```
Center(child: Column(mainAxisAlignment: center, children: [
  Text(field.emoji, style: TextStyle(fontSize: 48)),
  SizedBox(16),
  Text(field.label, Poppins SemiBold 20),
  SizedBox(24),
  SizedBox(width: 120,
    child: TextField(
      keyboardType: number,
      textAlign: center,
      style: Poppins Bold 36,
      decoration: InputDecoration(border: UnderlineInputBorder()),
      controller: controllers[field.key],
    )
  ),
  if (!field.required) Text("Optional — skip if not applicable", muted, 12),
]))
```

**Text Field Step:**
```
Center(child: Padding(padding: h 24, child: Column(mainAxisAlignment: center, children: [
  Text(field.emoji, style: TextStyle(fontSize: 48)),
  SizedBox(16),
  Text(field.label, Poppins SemiBold 20),
  SizedBox(24),
  TextField(
    maxLines: 5,
    controller: controllers[field.key],
    decoration: InputDecoration(hintText: field.hint ?? "Enter details..."),
  ),
])))
```

**Payment Array Step (secretary only):**
```
Column(children: [
  Text("💳", 48),
  Text("Payments Received", SemiBold 20),
  SizedBox(16),
  ...payments.asMap().entries.map((entry) =>
    Card(child: Padding(padding: 12, child: Column(children: [
      TextField(label: "Customer", controller: entry.value.customerCtrl),
      SizedBox(8),
      Row([
        Expanded(TextField(label: "Amount (₹)", keyboardType: number, controller: entry.value.amountCtrl)),
        SizedBox(8),
        Expanded(DropdownButtonFormField(label: "Type", items: ['cash', 'upi', 'bank', 'cheque'],
          value: entry.value.type)),
      ]),
      if (payments.length > 1)
        TextButton.icon(icon: Icon(Icons.delete, destructive), label: Text("Remove"), onPressed: () => removePayment(entry.key)),
    ])))
  ),
  TextButton.icon(icon: Icon(Icons.add, accent), label: Text("Add Payment", accent),
    onPressed: addPayment),
])
```

**Review Step:**
```
ListView(padding: 16, children: [
  Text("📋", 48, center),
  Text("Review Your Report", SemiBold 20, center),
  SizedBox(16),
  ...reportData.entries.map((e) =>
    ListTile(
      title: Text(fieldLabel(e.key), 13),
      subtitle: Text(e.value.toString(), SemiBold 15),
      dense: true,
    )
  ),
])
```

**Submit behavior:**
1. Collect all field values into `Map<String, dynamic>`
2. For number fields: parse to int/double
3. For payment arrays: serialize as `[{customer, amount, type}, ...]`
4. Call `ApiService().submitReport(date, data)`
5. On success: show success screen with ✅ animation, auto-return to dashboard after 2s
6. On error: show toast with error message

### 9.10 Reports View — Admin (`screens/reports_view_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("Reports")),
  body: Column(children: [
    // Date picker bar
    Container(padding: 16, child: Row(children: [
      IconButton(Icons.chevron_left, onPressed: () => changeDate(-1)),
      Expanded(child: GestureDetector(
        onTap: () => showDatePicker(...),
        child: Text(formattedDate, SemiBold 16, center),
      )),
      IconButton(Icons.chevron_right, onPressed: () => changeDate(1)),
    ])),

    // Stats bar
    Container(padding: h 16, child: Row(mainAxisAlignment: spaceEvenly, children: [
      _Stat("Submitted", "${summary.submitted}/${summary.totalStaff}", green),
      _Stat("Pending", "${summary.pending}", amber),
    ])),
    SizedBox(8),

    // Tabs: Submitted / Missing
    TabBar(tabs: [Tab(text: "Submitted"), Tab(text: "Missing")]),
    Expanded(child: TabBarView(children: [
      // Submitted list
      ListView(children: summary.reports.map((r) =>
        ExpansionTile(
          leading: CircleAvatar(child: Text(r.emoji)),
          title: Text(r.name),
          subtitle: Text("${r.roleLabel} • ${r.time}"),
          children: [
            // Decoded report_data fields
            ...r.reportData.entries.map((e) =>
              ListTile(title: Text(e.key.humanize()), trailing: Text(e.value.toString()), dense: true)
            ),
          ],
        )
      ).toList()),
      // Missing list
      ListView(children: missingStaff.map((s) =>
        ListTile(
          leading: CircleAvatar(child: Text(roleEmojis[s.role])),
          title: Text(s.name),
          subtitle: Text(s.roleLabel),
          trailing: Icon(Icons.warning_amber, color: amber),
        )
      ).toList()),
    ])),
  ]),
)
```

**API Calls:** `ApiService().getSummary(date)` and `ApiService().getMissing()` (for today only).

### 9.11 Team Management — Admin (`screens/team_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("Team")),
  body: RefreshIndicator(
    child: ListView(children: teamList.map((s) =>
      ListTile(
        leading: CircleAvatar(
          backgroundColor: s.active ? accentLight : muted,
          child: Text(s.emoji),
        ),
        title: Text(s.name, style: TextStyle(
          fontWeight: w500,
          decoration: s.active ? null : TextDecoration.lineThrough,
        )),
        subtitle: Text("${s.label} • ${s.activeTasks ?? 0} active tasks"),
        trailing: Row(mainAxisSize: min, children: [
          // Active/Inactive toggle
          Switch(value: s.active, onChanged: (_) => _toggleMember(s)),
          IconButton(Icons.edit, onPressed: () => _editMember(s)),
        ]),
        onTap: () => _editMember(s),
      )
    ).toList()),
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () => _addMember(),
    child: Icon(Icons.person_add),
  ),
)
```

**API:** `ApiService().getTeamList()`, `toggleTeamMember(id)`.

### 9.12 Team Add/Edit (`screens/team_edit_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text(isEdit ? "Edit Member" : "Add Member")),
  body: Form(child: ListView(padding: 16, children: [
    TextFormField(label: "Name *", controller: nameCtrl, validator: required),
    SizedBox(16),
    DropdownButtonFormField(label: "Role *", value: role,
      items: AppConstants.roleLabels.entries.map((e) =>
        DropdownMenuItem(value: e.key, child: Text("${AppConstants.roleEmojis[e.key]} ${e.value}"))
      ).toList(),
    ),
    SizedBox(16),
    TextFormField(label: "4-Digit PIN ${isEdit ? '(leave blank to keep)' : '*'}",
      keyboardType: number, maxLength: 4, obscureText: true,
      controller: pinCtrl, validator: isEdit ? null : required),
    SizedBox(16),
    TextFormField(label: "Telegram ID (optional)", controller: telegramCtrl),
    SizedBox(24),
    ElevatedButton(isEdit ? "Update" : "Add Member", onPressed: _save, minimumSize: Size(inf, 48)),
  ])),
)
```

**API:** `addTeamMember(...)` or `updateTeamMember(...)`.

### 9.13 Settings — Admin (`screens/settings_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("Settings")),
  body: ListView(children: [
    SectionHeader("General"),
    ListTile(title: Text("Company Name"), subtitle: Text("Getlead Analytics"), trailing: Icon(Icons.edit)),
    ListTile(title: Text("Report Deadline"), subtitle: Text("6:00 PM"), trailing: Icon(Icons.edit)),
    SwitchListTile(title: Text("Weekend Reports"), value: weekendReports, onChanged: _toggle),

    SectionHeader("Notifications"),
    SwitchListTile(title: Text("Report Reminders"), value: true),
    SwitchListTile(title: Text("Task Notifications"), value: true),

    SectionHeader("Account"),
    ListTile(title: Text("Logout"), leading: Icon(Icons.logout, color: destructive),
      onTap: _logout),
  ]),
)
```

### 9.14 Profile — Staff (`screens/profile_screen.dart`)

**Layout:**
```
Scaffold(
  appBar: AppBar(title: Text("Profile")),
  body: ListView(children: [
    // Profile card
    Container(padding: 24, alignment: center, child: Column(children: [
      CircleAvatar(radius: 40, backgroundColor: accentLight,
        child: Text(roleEmojis[role], style: TextStyle(fontSize: 32))),
      SizedBox(12),
      Text(name, SemiBold 20),
      Text(roleLabel, muted 14),
    ])),
    Divider(),
    ListTile(title: Text("Role"), trailing: Text("$emoji $roleLabel")),
    ListTile(title: Text("Report Streak"), trailing: Text("$streak days 🔥")),
    ListTile(title: Text("Tasks Completed"), trailing: Text("$completedMonth this month")),
    Divider(),
    ListTile(
      leading: Icon(Icons.logout, color: destructive),
      title: Text("Sign Out", style: TextStyle(color: destructive)),
      onTap: _logout,
    ),
  ]),
)
```

---

## 10. State Management

Use **Provider** for simplicity.

### `providers/auth_provider.dart`

```dart
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

  Future<String?> login(int staffId, String pin) async {
    final result = await _auth.login(staffId, pin);
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
```

### `providers/tasks_provider.dart`

```dart
class TasksProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  bool _loading = false;
  int _total = 0;
  int _pages = 1;
  int _currentPage = 1;
  String? _statusFilter;
  String? _priorityFilter;
  String? _search;
  bool _showAllTasks = false; // admin toggle

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  int get total => _total;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  bool get showAllTasks => _showAllTasks;

  void setStatusFilter(String? s) { _statusFilter = s; refresh(); }
  void setPriorityFilter(String? p) { _priorityFilter = p; refresh(); }
  void setSearch(String? q) { _search = q; refresh(); }
  void toggleAllTasks() { _showAllTasks = !_showAllTasks; refresh(); }

  Future<void> refresh({int? staffId}) async {
    _currentPage = 1;
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.getTasks(
        assignedTo: _showAllTasks ? null : staffId,
        status: _statusFilter,
        priority: _priorityFilter,
        search: _search,
        page: 1,
      );
      _tasks = result.tasks;
      _total = result.total;
      _pages = result.pages;
    } catch (e) {
      // Handle error
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore({int? staffId}) async {
    if (_currentPage >= _pages || _loading) return;
    _currentPage++;
    try {
      final result = await _api.getTasks(
        assignedTo: _showAllTasks ? null : staffId,
        status: _statusFilter,
        priority: _priorityFilter,
        search: _search,
        page: _currentPage,
      );
      _tasks.addAll(result.tasks);
      notifyListeners();
    } catch (_) { _currentPage--; }
  }
}
```

### `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tasks_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GetleadHQApp());
}

class GetleadHQApp extends StatelessWidget {
  const GetleadHQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
      ],
      child: MaterialApp(
        title: 'Getlead HQ',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            if (auth.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.loggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
```

---

## 11. Offline & Caching

### Strategy

1. **Cache GET responses** in SharedPreferences as JSON strings with timestamp
2. **Show cached data** when offline (check with `connectivity_plus`)
3. **Queue POST submissions** (report submissions, task updates) when offline
4. **Process queue** when connectivity returns

### `services/cache_service.dart`

```dart
class CacheService {
  static Future<void> cache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  static Future<T?> getCached<T>(String key, {Duration maxAge = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$key');
    if (raw == null) return null;
    final parsed = jsonDecode(raw);
    final ts = DateTime.parse(parsed['timestamp']);
    if (DateTime.now().difference(ts) > maxAge) return null;
    return parsed['data'] as T;
  }

  // Offline queue for POST operations
  static Future<void> queueAction(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    queue.add(jsonEncode(action));
    await prefs.setStringList('offline_queue', queue);
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_queue');
  }
}
```

---

## 12. Build & Deploy

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### App Icon

Use `flutter_launcher_icons` package. Create a simple icon:
- Background: `#18181B` (near-black)
- Foreground: White text "G" in Poppins Bold with teal accent dot

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 23
  adaptive_icon_background: "#18181B"
  adaptive_icon_foreground: "assets/icon_foreground.png"
```

### Splash Screen

Use `flutter_native_splash`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/splash_logo.png"
  android_12:
    color: "#FFFFFF"
    icon_background_color: "#18181B"
```

---

## Common Widgets Reference

### `widgets/kpi_card.dart`

```dart
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.foreground)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground)),
      ]),
    );
  }
}
```

### `widgets/status_badge.dart`

```dart
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ').capitalize();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.statusColor(status),
      )),
    );
  }
}
```

### `widgets/priority_dot.dart`

```dart
class PriorityDot extends StatelessWidget {
  final String priority;
  const PriorityDot(this.priority);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.priorityColor(priority),
      ),
    );
  }
}
```

### `widgets/skeleton_loader.dart`

```dart
// Use shimmer package for loading skeletons
class SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.muted,
      highlightColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

---

## Utility Functions

```dart
// lib/utils/helpers.dart

import 'package:intl/intl.dart';

String timeAgo(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

String formatDate(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d, yyyy').format(date);
}

String formatDateShort(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d').format(date);
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String humanize() => replaceAll('_', ' ').capitalize();
}
```

---

## Summary of API Calls by Screen

| Screen | API Call | Method | Auth |
|--------|----------|--------|------|
| Login | `?action=staff` | GET | api_token |
| Login | `mobile_login` | POST | none |
| Admin Dashboard | `?action=dashboard_stats` | GET | api_token |
| My Dashboard | `mobile_my_dashboard` | POST | mobile_token |
| Tasks List | `?action=tasks` | GET | api_token |
| Task Detail | `?action=task_detail&task_id=X` | GET | api_token |
| Task Update | `task_update` | POST | mobile_token |
| Task Comment | `task_comment` | POST | mobile_token |
| Task Delete | `task_delete` | POST | mobile_token |
| Create Task | `task_create` | POST | mobile_token |
| Daily Report | `mobile_submit_report` | POST | mobile_token |
| Reports View | `?action=summary&date=X` | GET | api_token |
| Missing Reports | `?action=missing` | GET | api_token |
| Today Reports | `?action=today` | GET | api_token |
| Team List | `?action=team_list` | GET | api_token |
| Team Add | `team_add` | POST | mobile_token |
| Team Update | `team_update` | POST | mobile_token |
| Team Toggle | `team_toggle` | POST | mobile_token |
| Settings | `settings_update` | POST | mobile_token |
| Token Verify | `mobile_verify` | POST | token in body |
| Logout | `mobile_logout` | POST | token in body |

---

## 🚫 REMINDERS

1. **NO PURPLE** — Not in themes, not in gradients, not anywhere
2. **Font: Poppins** — Always use `GoogleFonts.poppins()`
3. **Primary: Near-black `#18181B`** — Not pure black, not gray
4. **Accent: Teal `#14B8A6`** — For highlights, FABs, selected states
5. **Clean, minimal** — shadcn/ui inspired. Thin borders, subtle shadows, plenty of whitespace
6. **Import the constants file** — `import '../config/constants.dart';` in every file that uses colors/constants

---

*This document is the single source of truth for building the Getlead HQ Flutter app. Every screen, every API call, every color, every widget is specified above.*
