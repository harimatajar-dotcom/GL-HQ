import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/projects_provider.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final Project? project;

  const CreateProjectScreen({super.key, this.project});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _status = 'active';
  int? _projectLead;
  DateTime? _startDate;
  DateTime? _targetDate;
  List<StaffItem> _staff = [];
  bool _loading = false;
  bool _saving = false;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    if (isEditing) {
      _loadProjectData();
    }
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      final staff = await ApiService().getStaff();
      if (mounted) {
        setState(() {
          _staff = staff
              .map((s) => StaffItem(id: s.id, name: s.name))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _loadProjectData() {
    final p = widget.project!;
    _nameController.text = p.name;
    _descController.text = p.description ?? '';
    _status = p.status;
    _projectLead = p.projectLead;
    if (p.startDate != null) {
      _startDate = DateTime.tryParse(p.startDate!);
    }
    if (p.targetDate != null) {
      _targetDate = DateTime.tryParse(p.targetDate!);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<ProjectsProvider>();
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final startDate = _startDate != null
        ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
        : null;
    final targetDate = _targetDate != null
        ? '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}'
        : null;

    bool success;
    if (isEditing) {
      success = await provider.updateProject(
        widget.project!.id,
        name: name,
        description: description.isEmpty ? null : description,
        status: _status,
        projectLead: _projectLead,
        startDate: startDate,
        targetDate: targetDate,
      );
    } else {
      success = await provider.addProject(
        name: name,
        description: description.isEmpty ? null : description,
        status: _status,
        projectLead: _projectLead,
        startDate: startDate,
        targetDate: targetDate,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${provider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Project' : 'New Project',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    'Project Name *',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter project name',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: 'What is this project about?',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                    style: GoogleFonts.poppins(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Status and Lead row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(),
                              style: GoogleFonts.poppins(),
                              items: [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.teal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Active'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'on_hold',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('On Hold'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Completed'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'archived',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.slate,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Archived'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Lead',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _projectLead,
                              decoration: const InputDecoration(),
                              style: GoogleFonts.poppins(),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('— None —'),
                                ),
                                ..._staff.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                )),
                              ],
                              onChanged: (v) => setState(() => _projectLead = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dates row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                                      : '— Select —',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _targetDate ??
                                      DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() => _targetDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.event_outlined),
                                ),
                                child: Text(
                                  _targetDate != null
                                      ? '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}'
                                      : '— Select —',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Project' : 'Create Project',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class StaffItem {
  final int id;
  final String name;

  StaffItem({required this.id, required this.name});
}
