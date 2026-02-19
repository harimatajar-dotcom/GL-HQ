import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/staff.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = ApiService();

  List<Staff> _staffList = [];
  final Set<int> _selectedAssignees = {};
  String _priority = 'normal';
  String? _dueDate;
  String? _category;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _api.getStaff();
      setState(() => _staffList = staff.where((s) => s.active).toList());
    } catch (_) {}
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final assignees = _selectedAssignees.isEmpty && !auth.isAdmin
          ? [auth.staffId!]
          : _selectedAssignees.toList();

      final result = await _api.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignees: assignees,
        priority: _priority,
        dueDate: _dueDate,
        category: _category,
      );

      if (result['ok'] == true) {
        Fluttertoast.showToast(msg: 'Task created');
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: result['error'] ?? 'Failed to create task');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error creating task');
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                labelStyle: GoogleFonts.poppins(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.poppins(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Assign to (admin only)
            if (isAdmin && _staffList.isNotEmpty) ...[
              Text('Assign to', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _staffList.map((s) => FilterChip(
                  label: Text('${s.emoji} ${s.name}', style: GoogleFonts.poppins(fontSize: 12)),
                  selected: _selectedAssignees.contains(s.id),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedAssignees.add(s.id);
                      } else {
                        _selectedAssignees.remove(s.id);
                      }
                    });
                  },
                  selectedColor: AppColors.accentLight,
                  checkmarkColor: AppColors.accent,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Priority
            Text('Priority', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'high', label: Text('High')),
                ButtonSegment(value: 'urgent', label: Text('Urgent')),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.accentLight,
                selectedForegroundColor: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 16),

            // Due date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _dueDate != null ? formatDate(_dueDate!) : 'Select due date',
                style: GoogleFonts.poppins(),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.poppins(),
              ),
              items: AppConstants.categoryEmojis.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text('${e.value} ${e.key[0].toUpperCase()}${e.key.substring(1)}',
                            style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Create Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('MMM d, yyyy').format(date);
  }
}
