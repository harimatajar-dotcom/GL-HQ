import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final dash = dashboard.myDashboard;
    final role = auth.role ?? '';
    final emoji = AppConstants.roleEmojis[role] ?? '👤';
    final roleLabel = AppConstants.roleLabels[role] ?? role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accentLight,
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.name ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
                ),
                Text(
                  roleLabel,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text('Role', style: GoogleFonts.poppins()),
            trailing: Text('$emoji $roleLabel', style: GoogleFonts.poppins()),
          ),
          ListTile(
            title: Text('Report Streak', style: GoogleFonts.poppins()),
            trailing: Text(
              '${dash?.reportStreak ?? 0} days 🔥',
              style: GoogleFonts.poppins(),
            ),
          ),
          ListTile(
            title: Text('Tasks Completed', style: GoogleFonts.poppins()),
            trailing: Text(
              '${dash?.tasksCompletedMonth ?? 0} this month',
              style: GoogleFonts.poppins(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.destructive),
            title: Text(
              'Sign Out',
              style: GoogleFonts.poppins(color: AppColors.destructive),
            ),
            onTap: () async {
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
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
