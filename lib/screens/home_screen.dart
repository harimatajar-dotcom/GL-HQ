import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'my_dashboard_screen.dart';
import 'tasks_screen.dart';
import 'projects_screen.dart';
import 'assets_screen.dart';
import 'report_history_screen.dart';
import 'team_screen.dart';
import 'reports_view_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'analytics_screen.dart';
import 'touchpoint_screen.dart';
import 'chatlogs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

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
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final name = auth.name ?? 'User';
    final role = auth.role ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleLabel = AppConstants.roleLabels[role] ?? role;
    final roleEmoji = AppConstants.roleEmojis[role] ?? '';

    final screens = [
      isAdmin ? const AdminDashboardScreen() : const MyDashboardScreen(),
      const TasksScreen(),
      const ProjectsScreen(),
      const AssetsScreen(),
      const ReportHistoryScreen(),
      isAdmin ? const ReportsViewScreen() : const ProfileScreen(),
      isAdmin ? const TeamScreen() : const SettingsScreen(),
    ];

    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with accent ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$roleEmoji $roleLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accentLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation items
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.task_alt_rounded,
              label: 'Tasks',
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.folder_outlined,
              label: 'Projects',
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.inventory_2_rounded,
              label: 'Assets',
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.edit_note_rounded,
              label: 'Daily Report',
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: isAdmin ? Icons.bar_chart_rounded : Icons.person_rounded,
              label: isAdmin ? 'Reports' : 'Profile',
              selected: _currentIndex == 5,
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: isAdmin ? Icons.people_rounded : Icons.settings_rounded,
              label: isAdmin ? 'Team' : 'Settings',
              selected: _currentIndex == 6,
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 16, indent: 24, endIndent: 24),
            if (isAdmin) ...[
              _DrawerItem(
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.favorite_outline,
                label: 'TouchPoint',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TouchpointScreen()),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.forum_outlined,
                label: 'Chat Logs',
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatlogsScreen()),
                  );
                },
              ),
            ],

            const Spacer(),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: AppColors.destructive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: AppColors.destructive, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: GoogleFonts.poppins(
                            color: AppColors.destructive,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Company branding
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Divider(height: 1, indent: 24, endIndent: 24),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 72,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Getlead Analytics Pvt Ltd',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Projects',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Assets',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_rounded),
            label: 'Report',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Team',
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
        ],
      ),
    );
  }

  void switchToReportTab() {
    setState(() => _currentIndex = 4);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.accentLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.accent : AppColors.mutedForeground,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.foreground : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
