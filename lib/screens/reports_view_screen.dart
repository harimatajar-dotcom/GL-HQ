import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/report_provider.dart';
import '../utils/helpers.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';

class ReportsViewScreen extends StatefulWidget {
  const ReportsViewScreen({super.key});

  @override
  State<ReportsViewScreen> createState() => _ReportsViewScreenState();
}

class _ReportsViewScreenState extends State<ReportsViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<ReportProvider>().loadSummary(dateStr);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      if (_selectedDate.isAfter(DateTime.now())) {
        _selectedDate = DateTime.now();
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final summary = reportProvider.summary;
    final submitted = (summary?['reports'] as List?) ?? [];
    final missing = reportProvider.missing;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Date picker bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadData();
                      }
                    },
                    child: Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)))
                      ? () => _changeDate(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Stats bar
          if (summary != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(
                    'Submitted',
                    '${submitted.length}/${summary['total_staff'] ?? 0}',
                    AppColors.green,
                  ),
                  _Stat(
                    'Pending',
                    '${missing.length}',
                    AppColors.amber,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.foreground,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.accent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Submitted'),
              Tab(text: 'Missing'),
            ],
          ),

          // Tab content
          Expanded(
            child: reportProvider.loading
                ? const SkeletonList()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Submitted list
                      submitted.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox,
                              title: 'No reports submitted',
                              subtitle: 'No reports for this date yet',
                            )
                          : ListView.builder(
                              itemCount: submitted.length,
                              itemBuilder: (_, i) {
                                final r = submitted[i] as Map<String, dynamic>;
                                final reportData = r['report_data'];
                                Map<String, dynamic> decoded = {};
                                if (reportData is Map<String, dynamic>) {
                                  decoded = reportData;
                                } else if (reportData is String) {
                                  try {
                                    decoded = Map<String, dynamic>.from(
                                      (reportData as dynamic) is String
                                          ? {}
                                          : reportData as Map,
                                    );
                                  } catch (_) {}
                                }

                                return ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accentLight,
                                    child: Text(
                                      AppConstants.roleEmojis[r['role']] ?? '👤',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  title: Text(
                                    r['name'] ?? '',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '${AppConstants.roleLabels[r['role']] ?? r['role']} • ${r['submitted_at'] ?? ''}',
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                  children: decoded.entries.map((e) => ListTile(
                                    title: Text(
                                      e.key.replaceAll('_', ' ').capitalize(),
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    trailing: Text(
                                      e.value is List ? '${(e.value as List).length} items' : e.value.toString(),
                                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    dense: true,
                                  )).toList(),
                                );
                              },
                            ),
                      // Missing list
                      missing.isEmpty
                          ? const EmptyState(
                              icon: Icons.check_circle_outline,
                              title: 'All reports submitted',
                              subtitle: 'Everyone has submitted their report',
                            )
                          : ListView.builder(
                              itemCount: missing.length,
                              itemBuilder: (_, i) {
                                final s = missing[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.muted,
                                    child: Text(
                                      AppConstants.roleEmojis[s['role']] ?? '👤',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  title: Text(
                                    s['name'] ?? '',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    AppConstants.roleLabels[s['role']] ?? s['role'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                  trailing: const Icon(Icons.warning_amber, color: AppColors.amber),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground)),
      ],
    );
  }
}
