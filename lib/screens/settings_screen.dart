import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_header.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  bool _weekendReports = false;
  bool _reportReminders = true;
  bool _taskNotifications = true;
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weekendReports = prefs.getBool('setting_weekend_reports') ?? false;
      _reportReminders = prefs.getBool('setting_report_reminders') ?? true;
      _taskNotifications = prefs.getBool('setting_task_notifications') ?? true;
      _loadingSettings = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_$key', value);
    try {
      await _api.updateSetting(key, value);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Setting saved locally');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SectionHeader('General'),
                ),
                ListTile(
                  title: Text('Company Name', style: GoogleFonts.poppins()),
                  subtitle: Text('Getlead Analytics', style: GoogleFonts.poppins(color: AppColors.mutedForeground)),
                  trailing: const Icon(Icons.edit, size: 18),
                ),
                ListTile(
                  title: Text('Report Deadline', style: GoogleFonts.poppins()),
                  subtitle: Text('6:00 PM', style: GoogleFonts.poppins(color: AppColors.mutedForeground)),
                  trailing: const Icon(Icons.edit, size: 18),
                ),
                SwitchListTile(
                  title: Text('Weekend Reports', style: GoogleFonts.poppins()),
                  value: _weekendReports,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _weekendReports = v);
                    _updateSetting('weekend_reports', v);
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SectionHeader('Notifications'),
                ),
                SwitchListTile(
                  title: Text('Report Reminders', style: GoogleFonts.poppins()),
                  value: _reportReminders,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _reportReminders = v);
                    _updateSetting('report_reminders', v);
                  },
                ),
                SwitchListTile(
                  title: Text('Task Notifications', style: GoogleFonts.poppins()),
                  value: _taskNotifications,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _taskNotifications = v);
                    _updateSetting('task_notifications', v);
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SectionHeader('Account'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.destructive),
                  title: Text('Logout', style: GoogleFonts.poppins(color: AppColors.destructive)),
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
}
