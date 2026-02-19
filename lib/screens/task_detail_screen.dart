import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/constants.dart';
import '../models/task.dart';
import '../models/comment.dart';
import '../models/history_entry.dart';
import '../models/staff.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';
import '../widgets/status_badge.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  final _api = ApiService();

  Task? _task;
  List<Comment> _comments = [];
  List<HistoryEntry> _history = [];
  List<Staff> _staffList = [];
  bool _loading = true;
  String? _selectedStatus;
  String? _selectedPriority;
  int? _selectedAssignee;

  @override
  void initState() {
    super.initState();
    _loadTask();
    _loadStaff();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() => _loading = true);
    try {
      final result = await _api.getTaskDetail(widget.taskId);
      setState(() {
        _task = result.task;
        _comments = result.comments;
        _history = result.history;
        _selectedStatus = result.task.status;
        _selectedPriority = result.task.priority;
        _selectedAssignee = result.task.assignedTo;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Failed to load task');
    }
  }

  Future<void> _loadStaff() async {
    try {
      _staffList = await _api.getStaff();
    } catch (_) {}
  }

  Future<void> _updateField(String field, dynamic value) async {
    try {
      await _api.updateTask(widget.taskId, {field: value});
      await _loadTask();
      Fluttertoast.showToast(msg: 'Task updated');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Update failed');
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await _api.addComment(widget.taskId, text);
      _commentController.clear();
      await _loadTask();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add comment');
    }
  }

  Future<void> _markComplete() async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as Complete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Add a completion note (optional)',
            hintStyle: GoogleFonts.poppins(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: Text('Complete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.updateTask(widget.taskId, {'status': 'done'});
      final note = noteController.text.trim();
      if (note.isNotEmpty) {
        await _api.addComment(widget.taskId, '✅ Completed: $note');
      }
      await _loadTask();
      Fluttertoast.showToast(msg: 'Task completed');
    }
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final canEdit = isAdmin || _task?.assignedTo == auth.staffId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Detail', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (isAdmin && _task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _api.deleteTask(widget.taskId);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const SkeletonList(count: 5)
          : _task == null
              ? const Center(child: Text('Task not found'))
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _loadTask,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Title
                      Text(
                        _task!.title,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Badges
                      Wrap(
                        spacing: 8,
                        children: [
                          StatusBadge(_task!.status),
                          _PriorityBadge(_task!.priority),
                          if (_task!.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_task!.categoryEmoji} ${_task!.category}',
                                style: GoogleFonts.poppins(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (_task!.description?.isNotEmpty == true) ...[
                        Text(
                          _task!.description!,
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Meta info
                      _MetaRow(icon: Icons.calendar_today, label: 'Due', value: _task!.dueDate != null ? formatDate(_task!.dueDate!) : 'No due date'),
                      _MetaRow(icon: Icons.person, label: 'Created by', value: _task!.creatorName ?? 'Unknown'),
                      _MetaRow(icon: Icons.access_time, label: 'Created', value: timeAgo(_task!.createdAt)),
                      if (_task!.assigneeName != null)
                        _MetaRow(icon: Icons.person_pin, label: 'Assigned to', value: _task!.assigneeName!),
                      const SizedBox(height: 16),

                      // Editable fields
                      if (canEdit) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: GoogleFonts.poppins(),
                          ),
                          items: ['pending', 'in_progress', 'done', 'blocked']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.replaceAll('_', ' ').capitalize(), style: GoogleFonts.poppins()),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null && v != _task!.status) {
                              setState(() => _selectedStatus = v);
                              _updateField('status', v);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              labelStyle: GoogleFonts.poppins(),
                            ),
                            items: ['urgent', 'high', 'normal', 'low']
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.capitalize(), style: GoogleFonts.poppins()),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null && v != _task!.priority) {
                                setState(() => _selectedPriority = v);
                                _updateField('priority', v);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          if (_staffList.isNotEmpty)
                            DropdownButtonFormField<int>(
                              value: _selectedAssignee,
                              decoration: InputDecoration(
                                labelText: 'Assign to',
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              items: _staffList
                                  .where((s) => s.active)
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text('${s.emoji} ${s.name}', style: GoogleFonts.poppins()),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null && v != _task!.assignedTo) {
                                  setState(() => _selectedAssignee = v);
                                  _updateField('assigned_to', v);
                                }
                              },
                            ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Comments
                      const Divider(),
                      SectionHeader('Comments (${_comments.length})'),
                      ..._comments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${AppConstants.roleEmojis[c.staffRole] ?? '👤'} ${c.staffName ?? 'Unknown'}',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeAgo(c.createdAt),
                                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.mutedForeground),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.comment, style: GoogleFonts.poppins(fontSize: 14)),
                              ],
                            ),
                          )),
                      // Add comment
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: GoogleFonts.poppins(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addComment,
                            icon: const Icon(Icons.send, color: AppColors.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // History
                      const Divider(),
                      const SectionHeader('History'),
                      ..._history.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: AppColors.border,
                                  margin: const EdgeInsets.only(right: 12, left: 4),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.description, style: GoogleFonts.poppins(fontSize: 13)),
                                      Text(
                                        timeAgo(h.createdAt),
                                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
      bottomNavigationBar: _task != null && _task!.status != 'done'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _markComplete,
                  icon: const Icon(Icons.check_circle),
                  label: Text('Mark as Complete', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.mutedForeground)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge(this.priority);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.priorityColor(priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.capitalize(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.priorityColor(priority),
        ),
      ),
    );
  }
}

