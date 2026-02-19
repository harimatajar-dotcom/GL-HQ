import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/skeleton_loader.dart';
import 'home_screen.dart';

class MyDashboardScreen extends StatefulWidget {
  const MyDashboardScreen({super.key});

  @override
  State<MyDashboardScreen> createState() => _MyDashboardScreenState();
}

class _MyDashboardScreenState extends State<MyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadMyDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final dash = dashboard.myDashboard;

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
        onRefresh: () => dashboard.loadMyDashboard(),
        child: dashboard.loading && dash == null
            ? const SkeletonList(count: 6)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text(
                    'Hey, ${auth.name} 👋',
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
                  if (dash != null)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        KpiCard(
                          label: 'Tasks Open',
                          value: dash.tasksOpen.toString(),
                          icon: Icons.inbox,
                          color: AppColors.blue,
                        ),
                        KpiCard(
                          label: 'Done This Month',
                          value: dash.tasksCompletedMonth.toString(),
                          icon: Icons.check_circle,
                          color: AppColors.green,
                        ),
                        KpiCard(
                          label: 'Overdue',
                          value: dash.tasksOverdue.toString(),
                          icon: Icons.warning_rounded,
                          color: AppColors.destructive,
                        ),
                        KpiCard(
                          label: 'Completion',
                          value: dash.completionRate,
                          icon: Icons.speed,
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Report Streak Card
                  if (dash != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('🔥 Report Streak',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                              const Spacer(),
                              Text(
                                '${dash.reportStreak} days',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Calendar dots row (last 14 days)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildCalendarDots(dash.reportCalendar),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Quick Stats
                  if (dash != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip('Last Report', dash.lastReportDate ?? 'Never'),
                        _StatChip('This Week', '${dash.tasksCompletedWeek}'),
                        _StatChip('Avg Days', dash.avgCompletionDays),
                      ],
                    ),

                  // Report today nudge
                  if (dash != null && !dash.reportedToday)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('✏️ ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              "You haven't submitted today's report yet",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.findAncestorStateOfType<HomeScreenState>()?.switchToReportTab();
                            },
                            child: Text(
                              'Submit',
                              style: GoogleFonts.poppins(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildCalendarDots(List<dynamic> calendar) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final last14 = calendar.length > 14 ? calendar.sublist(calendar.length - 14) : calendar;

    if (last14.isEmpty) {
      return List.generate(7, (i) => Column(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.border,
            ),
          ),
          const SizedBox(height: 4),
          Text(days[i % 7], style: GoogleFonts.poppins(fontSize: 9, color: AppColors.mutedForeground)),
        ],
      ));
    }

    return last14.take(14).toList().asMap().entries.map((entry) {
      final day = entry.value;
      final submitted = day['submitted'] == true || day['submitted'] == 1;
      final date = DateTime.tryParse(day['date']?.toString() ?? '');
      final dayLabel = date != null ? DateFormat('E').format(date).substring(0, 1) : '';
      return Column(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: submitted ? AppColors.green : AppColors.border,
            ),
          ),
          const SizedBox(height: 4),
          Text(dayLabel, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.mutedForeground)),
        ],
      );
    }).toList();
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.mutedForeground),
        ),
      ],
    );
  }
}
