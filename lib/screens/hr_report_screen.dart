import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/hr_attendance.dart';
import '../providers/hr_report_provider.dart';

class HRReportScreen extends StatefulWidget {
  final String? initialDate;
  const HRReportScreen({super.key, this.initialDate});

  @override
  State<HRReportScreen> createState() => _HRReportScreenState();
}

class _HRReportScreenState extends State<HRReportScreen> {
  final _pageController = PageController();
  int _currentStep = 0; // 0 = attendance, 1 = report details
  late String _selectedDate = widget.initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _submitting = false;

  final _interviewsScheduledCtrl = TextEditingController();
  final _interviewsCompletedCtrl = TextEditingController();
  final _hrNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _interviewsScheduledCtrl.dispose();
    _interviewsCompletedCtrl.dispose();
    _hrNoteCtrl.dispose();
    super.dispose();
  }

  void _loadAttendance() {
    final provider = context.read<HRReportProvider>();
    provider.loadAttendanceList(_selectedDate).then((_) {
      if (mounted && provider.existingReport != null) {
        final r = provider.existingReport!;
        _interviewsScheduledCtrl.text =
            r.interviewsScheduled > 0 ? '${r.interviewsScheduled}' : '';
        _interviewsCompletedCtrl.text =
            r.interviewsCompleted > 0 ? '${r.interviewsCompleted}' : '';
        _hrNoteCtrl.text = r.hrNote ?? '';
      }
    });
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 1);
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 0);
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _onToggle(HrEmployee emp) async {
    if (emp.isPresent) {
      // Present → show dialog to choose absent type
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Mark ${emp.name} as',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AbsentOption(
                icon: Icons.timelapse,
                color: AppColors.amber,
                label: 'Half Day',
                onTap: () => Navigator.pop(ctx, 'half_day'),
              ),
              const SizedBox(height: 10),
              _AbsentOption(
                icon: Icons.event_busy,
                color: AppColors.destructive,
                label: 'Full Day Leave',
                onTap: () => Navigator.pop(ctx, 'full_day_leave'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
      if (result != null && mounted) {
        final res = await context.read<HRReportProvider>().markAbsent(
              date: _selectedDate,
              staffId: emp.staffId,
              status: result,
            );
        if (!res.ok && mounted) {
          Fluttertoast.showToast(msg: res.error ?? 'Failed');
        }
      }
    } else {
      // Absent → mark back as present
      final res = await context.read<HRReportProvider>().markAbsent(
            date: _selectedDate,
            staffId: emp.staffId,
            status: 'present',
          );
      if (!res.ok && mounted) {
        Fluttertoast.showToast(msg: res.error ?? 'Failed');
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<HRReportProvider>();
    final result = await provider.submitHRReport(
      date: _selectedDate,
      interviewsScheduled:
          int.tryParse(_interviewsScheduledCtrl.text) ?? 0,
      interviewsCompleted:
          int.tryParse(_interviewsCompletedCtrl.text) ?? 0,
      hrNote: _hrNoteCtrl.text,
    );
    setState(() => _submitting = false);

    if (result.ok && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      Fluttertoast.showToast(msg: result.error ?? 'Submission failed');
    }
  }

  void _showSuccessDialog() {
    final provider = context.read<HRReportProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.green),
            const SizedBox(height: 12),
            Text('Report Submitted!',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Date', value: _selectedDate),
            _SummaryRow(
                label: 'Present', value: '${provider.presentCount}'),
            _SummaryRow(
                label: 'Half Day', value: '${provider.halfDayCount}'),
            _SummaryRow(
                label: 'Leave', value: '${provider.fullDayLeaveCount}'),
            _SummaryRow(
              label: 'Interviews',
              value:
                  '${_interviewsCompletedCtrl.text.isEmpty ? 0 : _interviewsCompletedCtrl.text}/${_interviewsScheduledCtrl.text.isEmpty ? 0 : _interviewsScheduledCtrl.text}',
            ),
            if (_hrNoteCtrl.text.isNotEmpty)
              _SummaryRow(label: 'Note', value: _hrNoteCtrl.text),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('Done', style: GoogleFonts.poppins()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRReportProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('HR Daily Report',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          // Date picker
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(_selectedDate) ?? DateTime.now(),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                  _currentStep = 0;
                  _pageController.jumpToPage(0);
                  _interviewsScheduledCtrl.clear();
                  _interviewsCompletedCtrl.clear();
                  _hrNoteCtrl.clear();
                });
                _loadAttendance();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: AppColors.muted,
            color: AppColors.accent,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? _buildError()
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAttendanceScreen(provider),
                      _buildReportScreen(provider),
                    ],
                  ),
      ),
      bottomNavigationBar: provider.loading || provider.error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _currentStep == 0
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text('Next: Report Details',
                              style: GoogleFonts.poppins()),
                        ),
                      )
                    : Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _prevStep,
                            icon:
                                const Icon(Icons.arrow_back, size: 18),
                            label: Text('Attendance',
                                style: GoogleFonts.poppins()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.send, size: 18),
                              label: Text(
                                provider.alreadySubmitted
                                    ? 'Update Report'
                                    : 'Submit Report',
                                style: GoogleFonts.poppins(),
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
          const SizedBox(height: 12),
          Text('Failed to load attendance',
              style: GoogleFonts.poppins(color: AppColors.destructive)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadAttendance,
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SCREEN 1: Attendance Marking
  // ─────────────────────────────────────────

  Widget _buildAttendanceScreen(HRReportProvider provider) {
    return Column(
      children: [
        // Date display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.muted,
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d, yyyy')
                    .format(DateTime.parse(_selectedDate)),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (provider.alreadySubmitted) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Submitted',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green)),
                ),
              ],
            ],
          ),
        ),

        // Summary bar
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _StatChip(
                  emoji: '👥',
                  value: '${provider.totalCount}',
                  label: 'Total'),
              _divider(),
              _StatChip(
                  emoji: '✅',
                  value: '${provider.presentCount}',
                  label: 'Present'),
              _divider(),
              _StatChip(
                  emoji: '🌗',
                  value: '${provider.halfDayCount}',
                  label: 'Half Day'),
              _divider(),
              _StatChip(
                  emoji: '❌',
                  value: '${provider.fullDayLeaveCount}',
                  label: 'Leave'),
            ],
          ),
        ),

        // Info banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All employees are marked PRESENT by default. Uncheck to mark absent.',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Employee list
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _loadAttendance(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.employees.length,
              itemBuilder: (_, i) {
                final emp = provider.employees[i];
                return _EmployeeTile(
                  employee: emp,
                  onToggle: () => _onToggle(emp),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: AppColors.border);

  // ─────────────────────────────────────────
  // SCREEN 2: Report Details
  // ─────────────────────────────────────────

  Widget _buildReportScreen(HRReportProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance summary card (read-only from step 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance Summary',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(
                        label: 'Total',
                        value: '${provider.totalCount}',
                        color: AppColors.blue),
                    _MiniStat(
                        label: 'Present',
                        value: '${provider.presentCount}',
                        color: AppColors.green),
                    _MiniStat(
                        label: 'Half Day',
                        value: '${provider.halfDayCount}',
                        color: AppColors.amber),
                    _MiniStat(
                        label: 'Leave',
                        value: '${provider.fullDayLeaveCount}',
                        color: AppColors.destructive),
                  ],
                ),
                // Absent employees
                if (provider.absentEmployees.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Absent Today',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground)),
                  const SizedBox(height: 6),
                  ...provider.absentEmployees.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${AppConstants.roleEmojis[e.role] ?? "👤"} ${e.name}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: e.isHalfDay
                                    ? AppColors.amber
                                        .withValues(alpha: 0.12)
                                    : AppColors.destructive
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.isHalfDay
                                    ? '🌗 Half Day'
                                    : '❌ Full Day Leave',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: e.isHalfDay
                                      ? AppColors.amber
                                      : AppColors.destructive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interview section
          Text('Interview Details',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  controller: _interviewsScheduledCtrl,
                  label: 'Scheduled',
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberInput(
                  controller: _interviewsCompletedCtrl,
                  label: 'Completed',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // HR Note
          Text('HR Note',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _hrNoteCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Any notes for the day...',
              hintStyle:
                  GoogleFonts.poppins(color: AppColors.mutedForeground),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Employee Tile
// ──────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final HrEmployee employee;
  final VoidCallback onToggle;

  const _EmployeeTile({required this.employee, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.roleEmojis[employee.role] ?? '👤';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: employee.isPresent
              ? AppColors.border
              : employee.isHalfDay
                  ? AppColors.amber.withValues(alpha: 0.4)
                  : AppColors.destructive.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
        color: employee.isPresent
            ? null
            : employee.isHalfDay
                ? AppColors.amber.withValues(alpha: 0.04)
                : AppColors.destructive.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          // Role emoji avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.muted,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  employee.isPresent
                      ? employee.roleLabel
                      : employee.isHalfDay
                          ? '🌗 Half Day'
                          : '❌ Full Day Leave',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: employee.isPresent
                        ? AppColors.mutedForeground
                        : employee.isHalfDay
                            ? AppColors.amber
                            : AppColors.destructive,
                    fontWeight:
                        employee.isPresent ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Checkbox
          Checkbox(
            value: employee.isPresent,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Helper Widgets
// ──────────────────────────────────────

class _AbsentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AbsentOption(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatChip(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _NumberInput(
      {required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.mutedForeground)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.mutedForeground)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
