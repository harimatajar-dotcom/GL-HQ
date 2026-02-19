import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/helpers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_header.dart';
import 'home_screen.dart';
import '../widgets/skeleton_loader.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadAdminDashboard();
    });
  }

  IconData _activityIcon(String? action) => switch (action) {
    'created' => Icons.add_circle_outline,
    'status_changed' => Icons.swap_horiz,
    'assigned' => Icons.person_add_alt,
    'commented' => Icons.chat_bubble_outline,
    'completed' => Icons.check_circle_outline,
    _ => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final stats = dashboard.adminStats;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => dashboard.loadAdminDashboard(),
        child: dashboard.loading && stats == null
            ? const SkeletonList(count: 6)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text(
                    'Welcome back, ${auth.name} 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KPI Grid
                  if (stats != null)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        KpiCard(
                          label: 'Total Tasks',
                          value: stats.totalTasks.toString(),
                          icon: Icons.task,
                          color: AppColors.blue,
                        ),
                        KpiCard(
                          label: 'Overdue',
                          value: stats.overdueTasks.toString(),
                          icon: Icons.warning_rounded,
                          color: AppColors.destructive,
                        ),
                        KpiCard(
                          label: 'Done Today',
                          value: stats.completedToday.toString(),
                          icon: Icons.check_circle,
                          color: AppColors.green,
                        ),
                        KpiCard(
                          label: 'Report Rate',
                          value: stats.reportRate,
                          icon: Icons.assessment,
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Reports Missing Alert
                  if (stats != null && stats.reportsMissing.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber, color: AppColors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Reports Missing',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...stats.reportsMissing.map((s) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${AppConstants.roleEmojis[s['role']] ?? '👤'} ${s['name']}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Team Status
                  if (stats != null && stats.teamStatus.isNotEmpty) ...[
                    const SectionHeader('Team Status'),
                    ...stats.teamStatus.map((member) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentLight,
                        child: Text(
                          AppConstants.roleEmojis[member['role']] ?? '👤',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      title: Text(
                        member['name'] ?? '',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${member['pending_tasks'] ?? 0} pending • ${member['overdue_tasks'] ?? 0} overdue',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground),
                      ),
                      trailing: Text(
                        member['last_report'] ?? 'No report',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.mutedForeground),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Recent Activity
                  if (stats != null && stats.recentActivity.isNotEmpty) ...[
                    const SectionHeader('Recent Activity'),
                    ...stats.recentActivity.take(10).map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _activityIcon(a['action']),
                        size: 20,
                        color: AppColors.mutedForeground,
                      ),
                      title: Text(
                        a['description'] ?? a['action'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      subtitle: Text(
                        timeAgo(a['created_at'] ?? ''),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.mutedForeground),
                      ),
                      dense: true,
                    )),
                  ],
                ],
              ),
      ),
    );
  }
}
