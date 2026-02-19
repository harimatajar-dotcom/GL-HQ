import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'daily_report_screen.dart';
import 'home_screen.dart';
import 'hr_report_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadMyDashboard();
    });
  }

  // Build 30-day calendar data from API reportCalendar
  List<_DayInfo> _buildDays(List<dynamic> reportCalendar) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <_DayInfo>[];

    // Build a lookup map from the API data
    final reportMap = <String, Map<String, dynamic>>{};
    for (final entry in reportCalendar) {
      final date = entry['date']?.toString();
      if (date != null) {
        reportMap[date] = Map<String, dynamic>.from(entry);
      }
    }

    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final weekday = date.weekday; // 1=Mon, 7=Sun
      final isFuture = date.isAfter(today);
      final isToday = date == today;
      final isWeekend = weekday == 6 || weekday == 7; // Sat/Sun

      final entry = reportMap[dateStr];
      final submitted = entry != null &&
          (entry['submitted'] == true || entry['submitted'] == 1);
      final submittedAt = entry?['submitted_at']?.toString();

      _DayStatus status;
      if (isFuture) {
        status = _DayStatus.inactive;
      } else if (isWeekend) {
        status = _DayStatus.inactive;
      } else if (submitted) {
        status = _DayStatus.submitted;
      } else if (isToday) {
        status = _DayStatus.today;
      } else {
        status = _DayStatus.missed;
      }

      days.add(_DayInfo(
        date: date,
        dateStr: dateStr,
        status: status,
        isToday: isToday,
        submittedAt: submittedAt,
      ));
    }

    return days;
  }

  // Calculate stats from day info
  _Stats _calcStats(List<_DayInfo> days) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    int submitted = 0;
    int missed = 0;
    int monthWorkingDays = 0;
    int monthSubmitted = 0;

    for (final d in days) {
      if (d.status == _DayStatus.submitted) submitted++;
      if (d.status == _DayStatus.missed) missed++;

      // This month stats
      if (!d.date.isBefore(thisMonth)) {
        if (d.status != _DayStatus.inactive) {
          monthWorkingDays++;
          if (d.status == _DayStatus.submitted) monthSubmitted++;
        }
      }
    }

    // Calculate streak (consecutive submitted working days going backward from today)
    int streak = 0;
    for (int i = days.length - 1; i >= 0; i--) {
      final d = days[i];
      if (d.status == _DayStatus.inactive) continue;
      if (d.status == _DayStatus.submitted) {
        streak++;
      } else {
        break;
      }
    }

    final monthPct = monthWorkingDays > 0
        ? (monthSubmitted / monthWorkingDays * 100).round()
        : 0;

    return _Stats(
      submitted: submitted,
      missed: missed,
      streak: streak,
      monthPct: monthPct,
    );
  }

  void _openSubmitForm(BuildContext context, {String? date}) {
    final auth = context.read<AuthProvider>();
    final isHR = auth.role == 'hr' || auth.isAdmin;

    final Widget screen = isHR
        ? HRReportScreen(initialDate: date)
        : DailyReportScreen(initialDate: date);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) {
        context.read<DashboardProvider>().loadMyDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final dash = dashboard.myDashboard;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context
              .findAncestorStateOfType<HomeScreenState>()
              ?.scaffoldKey
              .currentState
              ?.openDrawer(),
        ),
        title: Text('Reports',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => dashboard.loadMyDashboard(),
        child: dashboard.loading && dash == null
            ? const SkeletonList(count: 6)
            : _buildContent(dash),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isHR = auth.role == 'hr' || auth.isAdmin;

    if (isHR) {
      return FloatingActionButton.extended(
        heroTag: 'report_fab',
        onPressed: () => _openSubmitForm(context),
        icon: const Icon(Icons.assignment_rounded),
        label: Text('HR Report',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      );
    }

    return FloatingActionButton(
      heroTag: 'report_fab',
      onPressed: () => _openSubmitForm(context),
      child: const Icon(Icons.edit_note),
    );
  }

  Widget _buildContent(dynamic dash) {
    final calendar = dash?.reportCalendar ?? [];
    final days = _buildDays(calendar);
    final stats = _calcStats(days);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section 1: Calendar Heatmap Strip
        _CalendarStrip(
          days: days,
          onTapDay: (day) {
            if (day.status == _DayStatus.submitted) {
              // View submitted report - for now show a toast
              _showReportDetail(day);
            } else if (day.status == _DayStatus.missed) {
              _openSubmitForm(context, date: day.dateStr);
            } else if (day.isToday) {
              _openSubmitForm(context);
            }
          },
        ),
        const SizedBox(height: 16),

        // Section 2: Stats Card
        _StatsCard(stats: stats),
        const SizedBox(height: 16),

        // Section 3: Report List
        Text(
          'History',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...days.reversed
            .where((d) => d.status != _DayStatus.inactive)
            .map((d) => _ReportRow(
                  day: d,
                  onSubmitLate: () =>
                      _openSubmitForm(context, date: d.dateStr),
                  onView: () => _showReportDetail(d),
                )),
      ],
    );
  }

  void _showReportDetail(_DayInfo day) {
    final formatted = DateFormat('MMMM d, yyyy').format(day.date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReportDetailSheet(
        dateStr: day.dateStr,
        formattedDate: formatted,
        submittedAt: day.submittedAt,
      ),
    );
  }
}

// ──────────────────────────────────────
// Data models
// ──────────────────────────────────────

enum _DayStatus { submitted, missed, inactive, today }

class _DayInfo {
  final DateTime date;
  final String dateStr;
  final _DayStatus status;
  final bool isToday;
  final String? submittedAt;

  _DayInfo({
    required this.date,
    required this.dateStr,
    required this.status,
    required this.isToday,
    this.submittedAt,
  });
}

class _Stats {
  final int submitted;
  final int missed;
  final int streak;
  final int monthPct;

  _Stats({
    required this.submitted,
    required this.missed,
    required this.streak,
    required this.monthPct,
  });
}

// ──────────────────────────────────────
// Section 1: Calendar Heatmap Strip
// ──────────────────────────────────────

class _CalendarStrip extends StatelessWidget {
  final List<_DayInfo> days;
  final ValueChanged<_DayInfo> onTapDay;

  const _CalendarStrip({required this.days, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Last 30 Days',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final day = days[i];
                return _CalendarDot(day: day, onTap: () => onTapDay(day));
              },
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _LegendDot(color: AppColors.accent, label: 'Submitted'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.destructive, label: 'Missed'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.border, label: 'Off/Future'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDot extends StatelessWidget {
  final _DayInfo day;
  final VoidCallback onTap;

  const _CalendarDot({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (day.status) {
      case _DayStatus.submitted:
        color = AppColors.accent;
        break;
      case _DayStatus.missed:
        color = AppColors.destructive;
        break;
      case _DayStatus.today:
        color = AppColors.amber;
        break;
      case _DayStatus.inactive:
        color = AppColors.border;
        break;
    }

    final dayNum = day.date.day.toString();
    final isClickable = day.status != _DayStatus.inactive;

    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        width: 36,
        margin: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: day.isToday
                    ? Border.all(color: AppColors.foreground, width: 2)
                    : null,
              ),
              child: day.status == _DayStatus.submitted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : day.status == _DayStatus.missed
                      ? const Icon(Icons.close, size: 14, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
                color: day.isToday
                    ? AppColors.foreground
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
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

// ──────────────────────────────────────
// Section 2: Stats Card
// ──────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final _Stats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  emoji: '✅',
                  value: '${stats.submitted}',
                  label: 'Submitted',
                  color: AppColors.accent,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  emoji: '❌',
                  value: '${stats.missed}',
                  label: 'Missed',
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  emoji: '🔥',
                  value: '${stats.streak} days',
                  label: 'Current Streak',
                  color: AppColors.amber,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  emoji: '📈',
                  value: '${stats.monthPct}%',
                  label: 'This Month',
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────
// Section 3: Report List
// ──────────────────────────────────────

class _ReportRow extends StatelessWidget {
  final _DayInfo day;
  final VoidCallback onSubmitLate;
  final VoidCallback onView;

  const _ReportRow({
    required this.day,
    required this.onSubmitLate,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(day.date);
    final dayName = day.isToday
        ? 'Today'
        : DateFormat('EEEE').format(day.date);
    final isSubmitted = day.status == _DayStatus.submitted;
    final isMissed = day.status == _DayStatus.missed || day.status == _DayStatus.today;

    // Allow late submission up to 7 days back
    final now = DateTime.now();
    final daysAgo = DateTime(now.year, now.month, now.day)
        .difference(DateTime(day.date.year, day.date.month, day.date.day))
        .inDays;
    final canSubmitLate = isMissed && daysAgo <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: day.isToday ? AppColors.accent : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(10),
        color: day.isToday ? AppColors.accentLight.withValues(alpha: 0.3) : null,
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dayName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Expanded(
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSubmitted
                        ? '✅ Submitted${day.submittedAt != null ? ' ${day.submittedAt}' : ''}'
                        : '❌ MISSED',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSubmitted
                          ? AppColors.accent
                          : AppColors.destructive,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (isSubmitted)
            _ActionChip(
              label: 'View',
              icon: Icons.visibility_outlined,
              color: AppColors.accent,
              onTap: onView,
            ),
          if (canSubmitLate && !day.isToday)
            _ActionChip(
              label: 'Submit',
              icon: Icons.edit_note,
              color: AppColors.amber,
              onTap: onSubmitLate,
            ),
          if (day.isToday && !isSubmitted)
            _ActionChip(
              label: 'Submit',
              icon: Icons.edit_note,
              color: AppColors.accent,
              onTap: onSubmitLate,
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Report Detail Bottom Sheet (fetches summary API)
// ──────────────────────────────────────

class _ReportDetailSheet extends StatefulWidget {
  final String dateStr;
  final String formattedDate;
  final String? submittedAt;

  const _ReportDetailSheet({
    required this.dateStr,
    required this.formattedDate,
    this.submittedAt,
  });

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  bool _loading = true;
  Map<String, dynamic>? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    final authName =
        context.read<AuthProvider>().name?.toLowerCase() ?? '';
    try {
      final api = ApiService();
      final summary = await api.getSummary(widget.dateStr);
      final reports = summary['reports'] as List? ?? [];
      Map<String, dynamic>? myReport;
      for (final r in reports) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        if (name == authName) {
          myReport = Map<String, dynamic>.from(r);
          break;
        }
      }

      if (mounted) {
        setState(() {
          _reportData = myReport;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Icon(Icons.check_circle, color: AppColors.green, size: 40),
          const SizedBox(height: 8),
          Text(
            'Report — ${widget.formattedDate}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.submittedAt != null)
            Text(
              'Submitted at ${widget.submittedAt}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          const Divider(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text('Failed to load report',
                            style: GoogleFonts.poppins(
                                color: AppColors.destructive)))
                    : _reportData == null
                        ? Center(
                            child: Text('No report data found',
                                style: GoogleFonts.poppins(
                                    color: AppColors.mutedForeground)))
                        : _buildReportContent(scrollCtrl),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ScrollController scrollCtrl) {
    // Parse report_data JSON
    final reportDataRaw = _reportData!['report_data'];
    Map<String, dynamic> fields = {};
    if (reportDataRaw is Map) {
      fields = Map<String, dynamic>.from(reportDataRaw);
    } else if (reportDataRaw is String && reportDataRaw.isNotEmpty) {
      try {
        fields = Map<String, dynamic>.from(jsonDecode(reportDataRaw));
      } catch (_) {}
    }

    final updatedAt = _reportData!['updated_at']?.toString();
    final role = _reportData!['role']?.toString() ?? '';

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        if (role.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppConstants.roleLabels[role] ?? role,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ...fields.entries.map((e) {
          final label = _formatFieldKey(e.key);
          final value = e.value;

          // Handle payment arrays
          if (value is List) {
            return _buildPaymentSection(label, value);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value?.toString().isEmpty == true
                        ? '—'
                        : value.toString(),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }),
        if (updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Last updated: $updatedAt',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentSection(String label, List payments) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          if (payments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('No payments',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.mutedForeground)),
            )
          else
            ...payments.map((p) {
              final customer = p['customer'] ?? '';
              final amount = p['amount'] ?? 0;
              final type = p['type'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(customer.toString(),
                          style: GoogleFonts.poppins(fontSize: 14)),
                    ),
                    Text(
                      '₹$amount',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatFieldKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
