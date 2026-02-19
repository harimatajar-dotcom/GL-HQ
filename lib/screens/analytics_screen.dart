import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/analytics_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAllAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final analytics = context.read<AnalyticsProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: analytics.fromDate, end: analytics.toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary),
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      analytics.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => analytics.loadAllAnalytics(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.mutedForeground,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Reports'),
            Tab(text: 'Team'),
            Tab(text: 'HR'),
            Tab(text: 'Marketing'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => analytics.loadAllAnalytics(),
        color: AppColors.accent,
        child: TabBarView(
          controller: _tabController,
          children: [
            _TasksTab(data: analytics.taskAnalytics, loading: analytics.loading),
            _ReportsTab(data: analytics.reportAnalytics, loading: analytics.loading),
            _TeamTab(data: analytics.teamAnalytics, loading: analytics.loading),
            _HRTab(data: analytics.hrAnalytics, loading: analytics.loading),
            _MarketingTab(data: analytics.marketingAnalytics, loading: analytics.loading),
          ],
        ),
      ),
    );
  }
}

// ============ TASKS TAB ============
class _TasksTab extends StatelessWidget {
  final AnalyticsData? data;
  final bool loading;

  const _TasksTab({this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
          ],
        ),
      );
    }

    if (data == null) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No data available',
        subtitle: 'Pull to refresh or change date range',
      );
    }

    final taskData = data!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          _buildKPIGrid(taskData),
          const SizedBox(height: 24),

          // Task Status Distribution
          _SectionCard(
            title: 'Task Status Distribution',
            icon: Icons.pie_chart_outline,
            child: _buildStatusDistribution(taskData.byCategory),
          ),
          const SizedBox(height: 16),

          // Performance by Person
          if (taskData.byPerson.isNotEmpty) ...[
            _SectionCard(
              title: 'Performance by Person',
              icon: Icons.people_outline,
              child: _buildPersonPerformance(taskData.byPerson),
            ),
            const SizedBox(height: 16),
          ],

          // Trend
          if (taskData.trend.isNotEmpty) ...[
            _SectionCard(
              title: 'Task Trend (Last 30 Days)',
              icon: Icons.trending_up,
              child: _buildTrendChart(taskData.trend),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKPIGrid(AnalyticsData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Tasks',
                value: data.totalCreated.toString(),
                icon: Icons.task_alt,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Completed',
                value: data.totalCompleted.toString(),
                icon: Icons.check_circle_outline,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Completion %',
                value: '${data.completionRate}%',
                icon: Icons.percent,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Overdue',
                value: data.overdueCount.toString(),
                icon: Icons.warning_amber,
                color: data.overdueCount > 0 ? AppColors.destructive : AppColors.slate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _KpiCard(
          label: 'Avg Completion Time',
          value: '${data.avgCompletionDays.toStringAsFixed(1)} days',
          icon: Icons.timer_outlined,
          color: AppColors.amber,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatusDistribution(List<ByCategoryData> categories) {
    final maxCount = categories.isEmpty ? 1 : categories.map((c) => c.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: categories.map((cat) {
        final percent = maxCount > 0 ? (cat.count / maxCount * 100).clamp(0, 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  cat.category.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFF2DD4BF)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  cat.count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonPerformance(List<ByPersonData> people) {
    final maxTotal = people.isEmpty ? 1 : people.map((p) => p.total).reduce((a, b) => a > b ? a : b);

    return Column(
      children: people.take(10).map((person) {
        final percent = maxTotal > 0 ? (person.total / maxTotal * 100).clamp(0, 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      person.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${person.completed}/${person.total}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: person.rate >= 80 ? const Color(0xFFD1FAE5) : 
                             person.rate >= 50 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${person.rate}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: person.rate >= 80 ? AppColors.green : 
                               person.rate >= 50 ? AppColors.amber : AppColors.destructive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFF2DD4BF)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendChart(List<TrendData> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxVal = [
      ...trend.map((t) => t.created),
      ...trend.map((t) => t.completed),
    ].reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.take(14).map((t) {
          final createdHeight = maxVal > 0 ? (t.created / maxVal * 100).clamp(5.0, 100.0) : 5.0;
          final completedHeight = maxVal > 0 ? (t.completed / maxVal * 100).clamp(5.0, 100.0) : 5.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: createdHeight,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 6,
                        height: completedHeight,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.dayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============ REPORTS TAB ============
class _ReportsTab extends StatelessWidget {
  final AnalyticsData? data;
  final bool loading;

  const _ReportsTab({this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [SkeletonCard(), SizedBox(height: 16), SkeletonCard()]),
      );
    }

    if (data == null || data!.reportsByPerson.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'No report data',
        subtitle: 'No daily reports submitted in this period',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Report Submission Rate',
            icon: Icons.assessment_outlined,
            child: _buildReportPerformance(data!.reportsByPerson),
          ),
          const SizedBox(height: 16),
          if (data!.streaks.isNotEmpty)
            _SectionCard(
              title: 'Submission Streaks 🔥',
              icon: Icons.local_fire_department,
              child: _buildStreaks(data!.streaks),
            ),
        ],
      ),
    );
  }

  Widget _buildReportPerformance(List<ReportPersonData> reports) {
    final maxTotal = reports.map((r) => r.totalDays).reduce((a, b) => a > b ? a : b);

    return Column(
      children: reports.map((r) {
        final percent = maxTotal > 0 ? (r.submitted / maxTotal * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${r.submitted}/${r.totalDays}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFF2DD4BF)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreaks(List<StreakData> streaks) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: streaks.where((s) => s.streak > 0).map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔥', style: GoogleFonts.poppins(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${s.streak}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                s.name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============ TEAM TAB ============
class _TeamTab extends StatelessWidget {
  final AnalyticsData? data;
  final bool loading;

  const _TeamTab({this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [SkeletonCard(), SizedBox(height: 16), SkeletonCard()]),
      );
    }

    if (data == null || data!.teamMembers.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No team data',
        subtitle: 'No team performance data available',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data!.teamMembers.length,
      itemBuilder: (context, index) {
        final member = data!.teamMembers[index];
        return _TeamMemberCard(member: member);
      },
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMemberData member;

  const _TeamMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF2DD4BF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      member.roleLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: member.productivityScore >= 80 ? const Color(0xFFD1FAE5) :
                         member.productivityScore >= 50 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${member.productivityScore}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: member.productivityScore >= 80 ? AppColors.green :
                           member.productivityScore >= 50 ? AppColors.amber : AppColors.destructive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Done', value: member.tasksCompleted.toString(), color: AppColors.green),
              _StatItem(label: 'Pending', value: member.tasksPending.toString(), color: AppColors.amber),
              _StatItem(label: 'Overdue', value: member.overdue.toString(), color: AppColors.destructive),
              _StatItem(label: 'Reports', value: member.reportsSubmitted.toString(), color: AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ HR TAB ============
class _HRTab extends StatelessWidget {
  final AnalyticsData? data;
  final bool loading;

  const _HRTab({this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [SkeletonCard(), SizedBox(height: 16), SkeletonCard()]),
      );
    }

    if (data?.hrData == null) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No HR data',
        subtitle: 'No attendance data available for this period',
      );
    }

    final hr = data!.hrData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Attendance Stats
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Present Days',
                  value: hr.presentDays.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Leave Days',
                  value: hr.leaveDays.toString(),
                  icon: Icons.event_busy,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KpiCard(
            label: 'Attendance Rate',
            value: '${hr.attendanceRate}%',
            icon: Icons.pie_chart,
            color: AppColors.teal,
            fullWidth: true,
          ),
          const SizedBox(height: 16),

          // Leave by Person
          if (hr.leaveByPerson.isNotEmpty)
            _SectionCard(
              title: 'Leave by Person',
              icon: Icons.person_off_outlined,
              child: Column(
                children: hr.leaveByPerson.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${p.totalLeaves} days',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ============ MARKETING TAB ============
class _MarketingTab extends StatelessWidget {
  final AnalyticsData? data;
  final bool loading;

  const _MarketingTab({this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [SkeletonCard(), SizedBox(height: 16), SkeletonCard()]),
      );
    }

    if (data?.marketing == null) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        title: 'No marketing data',
        subtitle: 'Connect marketing API to see data',
      );
    }

    final m = data!.marketing!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Revenue',
                  value: '₹${NumberFormat.compact().format(m.totalRevenue)}',
                  icon: Icons.currency_rupee,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Registrations',
                  value: NumberFormat.compact().format(m.totalRegistrations),
                  icon: Icons.person_add,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Conversion %',
                  value: '${m.conversionRate}%',
                  icon: Icons.trending_up,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Active Leads',
                  value: m.activeLeads.toString(),
                  icon: Icons.people,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Funnel
          if (m.funnel.isNotEmpty)
            _SectionCard(
              title: 'Conversion Funnel',
              icon: Icons.filter_alt_outlined,
              child: _buildFunnel(m.funnel),
            ),
          const SizedBox(height: 16),

          // Campaigns
          if (m.campaigns.isNotEmpty)
            _SectionCard(
              title: 'Top Campaigns',
              icon: Icons.campaign,
              child: _buildCampaigns(m.campaigns),
            ),
        ],
      ),
    );
  }

  Widget _buildFunnel(List<FunnelStageData> funnel) {
    final maxCount = funnel.isEmpty ? 1 : funnel.map((f) => f.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: funnel.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final width = maxCount > 0 ? (stage.count / maxCount * 100).clamp(20.0, 100.0) : 20.0;

        // Funnel effect - each step gets slightly narrower
        final funnelFactor = 1 - (index * 0.08);
        final adjustedWidth = width * funnelFactor;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: adjustedWidth / 100,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(AppColors.accent, const Color(0xFF2DD4BF), index * 0.1) ?? AppColors.accent,
                            Color.lerp(const Color(0xFF2DD4BF), AppColors.accent, index * 0.1) ?? const Color(0xFF2DD4BF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        stage.count.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                stage.stage,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampaigns(List<CampaignData> campaigns) {
    final maxLeads = campaigns.isEmpty ? 1 : campaigns.map((c) => c.leads).reduce((a, b) => a > b ? a : b);

    return Column(
      children: campaigns.take(10).map((c) {
        final percent = maxLeads > 0 ? (c.leads / maxLeads * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  c.name,
                  style: GoogleFonts.poppins(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                c.leads.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============ SHARED WIDGETS ============

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
