import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/report_field.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/report_provider.dart';
import 'home_screen.dart';

class DailyReportScreen extends StatefulWidget {
  final String? initialDate;
  const DailyReportScreen({super.key, this.initialDate});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  late String _selectedDate = widget.initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final List<_PaymentEntry> _payments = [_PaymentEntry()];
  bool _submitting = false;
  bool _submitted = false;

  List<ReportField> get _fields {
    final role = context.read<AuthProvider>().role ?? 'developer';
    return roleReportFields[role] ?? roleReportFields['developer']!;
  }

  int get _totalSteps => _fields.length + 2; // date + fields + review

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final field in _fields) {
        _controllers[field.key] = TextEditingController();
        _fieldFocusNodes[field.key] = FocusNode();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _fieldFocusNodes.values) {
      f.dispose();
    }
    for (final p in _payments) {
      p.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) => _autoFocusCurrentField());
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) => _autoFocusCurrentField());
    }
  }

  void _autoFocusCurrentField() {
    final fieldIndex = _currentStep - 1;
    if (fieldIndex >= 0 && fieldIndex < _fields.length) {
      final field = _fields[fieldIndex];
      if (field.type != FieldType.paymentArray) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _fieldFocusNodes[field.key]?.requestFocus();
          }
        });
      }
    }
  }

  Map<String, dynamic> _collectData() {
    final data = <String, dynamic>{};
    for (final field in _fields) {
      if (field.type == FieldType.paymentArray) {
        data[field.key] = _payments
            .where((p) => p.customerCtrl.text.isNotEmpty)
            .map((p) => {
                  'customer': p.customerCtrl.text,
                  'amount': double.tryParse(p.amountCtrl.text) ?? 0,
                  'type': p.type,
                })
            .toList();
      } else if (field.type == FieldType.number) {
        final text = _controllers[field.key]?.text ?? '';
        data[field.key] = int.tryParse(text) ?? 0;
      } else {
        data[field.key] = _controllers[field.key]?.text ?? '';
      }
    }
    return data;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<ReportProvider>();
    final result = await provider.submitReport(_selectedDate, _collectData());

    if (result.ok) {
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      // Refresh dashboard data so report history updates
      if (mounted) {
        context.read<DashboardProvider>().loadMyDashboard();
      }
      // Auto return after 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _currentStep = 0;
            _pageController.jumpToPage(0);
            for (final c in _controllers.values) {
              c.clear();
            }
          });
        }
      });
    } else {
      setState(() => _submitting = false);
      Fluttertoast.showToast(msg: result.error ?? 'Submission failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: AppColors.green),
              const SizedBox(height: 16),
              Text(
                'Report Submitted!',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Your daily report has been saved',
                style: GoogleFonts.poppins(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Daily Report', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.muted,
            color: AppColors.accent,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: _controllers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDateStep(),
                  ..._fields.map((field) => _buildFieldStep(field)),
                  _buildReviewStep(),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _prevStep,
                  child: Text('Back', style: GoogleFonts.poppins()),
                ),
              const Spacer(),
              if (_currentStep < _totalSteps - 1)
                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text('Next', style: GoogleFonts.poppins()),
                ),
              if (_currentStep == _totalSteps - 1)
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text('Submit', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Select Date', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Choose the date for your report',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_selectedDate)),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldStep(ReportField field) {
    if (field.type == FieldType.paymentArray) {
      return _buildPaymentStep(field);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(field.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(field.label, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            if (field.type == FieldType.number)
              SizedBox(
                width: 120,
                child: TextField(
                  focusNode: _fieldFocusNodes[field.key],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: UnderlineInputBorder()),
                  controller: _controllers[field.key],
                ),
              )
            else
              TextField(
                focusNode: _fieldFocusNodes[field.key],
                maxLines: 5,
                controller: _controllers[field.key],
                decoration: InputDecoration(
                  hintText: field.hint ?? 'Enter details...',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
            if (!field.required)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Optional — skip if not applicable',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep(ReportField field) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('💳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text('Payments Received', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ..._payments.asMap().entries.map((entry) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: entry.value.customerCtrl,
                        decoration: InputDecoration(
                          labelText: 'Customer',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value.amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount (₹)',
                                labelStyle: GoogleFonts.poppins(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: entry.value.type,
                              decoration: InputDecoration(
                                labelText: 'Type',
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              items: ['cash', 'upi', 'bank', 'cheque']
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t[0].toUpperCase() + t.substring(1),
                                            style: GoogleFonts.poppins()),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _payments[entry.key].type = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_payments.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _payments.removeAt(entry.key)),
                            icon: const Icon(Icons.delete, color: AppColors.destructive, size: 16),
                            label: Text('Remove',
                                style: GoogleFonts.poppins(color: AppColors.destructive, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _payments.add(_PaymentEntry())),
            icon: const Icon(Icons.add, color: AppColors.accent),
            label: Text('Add Payment', style: GoogleFonts.poppins(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final data = _collectData();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(child: Text('📋', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Review Your Report',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            DateFormat('MMMM d, yyyy').format(DateTime.parse(_selectedDate)),
            style: GoogleFonts.poppins(color: AppColors.mutedForeground),
          ),
        ),
        const SizedBox(height: 16),
        ...data.entries.map((e) {
          final field = _fields.where((f) => f.key == e.key).firstOrNull;
          return ListTile(
            title: Text(
              field?.label ?? e.key.replaceAll('_', ' '),
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.mutedForeground),
            ),
            subtitle: Text(
              e.value is List ? '${(e.value as List).length} entries' : e.value.toString(),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            dense: true,
          );
        }),
      ],
    );
  }
}

class _PaymentEntry {
  final customerCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String type = 'upi';

  void dispose() {
    customerCtrl.dispose();
    amountCtrl.dispose();
  }
}
