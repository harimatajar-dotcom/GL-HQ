import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../models/project.dart';
import '../models/staff.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  ProjectDetail? _detail;
  List<ProjectActivity> _activity = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ApiService().getProjectDetail(widget.projectId);
      final activity = await ApiService().getProjectActivity();
      
      if (mounted) {
        setState(() {
          _detail = detail;
          _activity = activity.where((a) => a.projectName == detail.project.name).toList();
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

  Future<void> _addTask() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AddTaskDialog(),
    );

    if (result != null && mounted) {
      final provider = context.read<ProjectsProvider>();
      final success = await provider.addProjectTask(
        projectId: widget.projectId,
        title: result['title'],
        description: result['description'],
        assignedTo: result['assignedTo'],
        priority: result['priority'],
        dueDate: result['dueDate'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${provider.error}')),
        );
      }
    }
  }

  Future<void> _editProject() async {
    if (_detail == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(project: _detail!.project),
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Project', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Delete this project? Tasks will be unlinked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ProjectsProvider>();
      final success = await provider.deleteProject(widget.projectId);

      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${provider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _detail?.project.name ?? 'Project Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isAdmin && !_loading)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editProject();
                } else if (value == 'delete') {
                  _deleteProject();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                      const SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.destructive)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const SkeletonList()
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error loading project',
                  subtitle: _error!,
                )
              : _detail == null
                  ? const EmptyState(
                      icon: Icons.folder_off_outlined,
                      title: 'Project not found',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 16),
                            // Progress
                            _buildProgressCard(),
                            const SizedBox(height: 16),
                            // Meta info
                            _buildMetaGrid(),
                            const SizedBox(height: 24),
                            // Tasks
                            _buildTasksSection(),
                            const SizedBox(height: 24),
                            // Recent Activity
                            if (_activity.isNotEmpty) ...[
                              _buildActivitySection(),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: !_loading && _detail != null
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final project = _detail!.project;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            project.statusColor.withValues(alpha: 0.1),
            AppColors.muted.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: project.statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: project.statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  project.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: project.statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (project.description != null && project.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              project.description!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final project = _detail!.project;
    final pending = _detail!.pendingTasks;
    final inProgress = _detail!.inProgressTasks;
    final done = _detail!.doneTasks;
    final blocked = _detail!.blockedTasks;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${project.progressPercent}%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: project.progressPercent / 100,
                backgroundColor: AppColors.muted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  project.isOverdue ? AppColors.destructive : AppColors.teal,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TaskStat(label: 'Done', value: done, color: AppColors.green),
                const SizedBox(width: 12),
                _TaskStat(label: 'In Progress', value: inProgress, color: AppColors.blue),
                const SizedBox(width: 12),
                _TaskStat(label: 'Pending', value: pending, color: AppColors.amber),
                const SizedBox(width: 12),
                _TaskStat(label: 'Blocked', value: blocked, color: AppColors.destructive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaGrid() {
    final project = _detail!.project;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _MetaItem(
          label: 'Project Lead',
          value: project.leadName ?? '—',
          icon: Icons.person_outline,
        ),
        _MetaItem(
          label: 'Start Date',
          value: project.startDate ?? '—',
          icon: Icons.calendar_today_outlined,
        ),
        _MetaItem(
          label: 'Target Date',
          value: project.targetDate ?? '—',
          icon: Icons.event_outlined,
          isOverdue: project.isOverdue,
        ),
        _MetaItem(
          label: 'Created By',
          value: project.creatorName ?? '—',
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildTasksSection() {
    final tasks = _detail!.tasks;
    final groups = {
      'pending': tasks.where((t) => t.status == 'pending').toList(),
      'in_progress': tasks.where((t) => t.status == 'in_progress').toList(),
      'blocked': tasks.where((t) => t.status == 'blocked').toList(),
      'done': tasks.where((t) => t.status == 'done').toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...groups.entries.expand((entry) {
          final status = entry.key;
          final statusTasks = entry.value;
          final label = switch (status) {
            'pending' => 'Pending',
            'in_progress' => 'In Progress',
            'blocked' => 'Blocked',
            'done' => 'Done',
            _ => status,
          };
          final color = switch (status) {
            'pending' => AppColors.amber,
            'in_progress' => AppColors.blue,
            'blocked' => AppColors.destructive,
            'done' => AppColors.green,
            _ => AppColors.slate,
          };

          return [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusTasks.length.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (statusTasks.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No tasks',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    ...statusTasks.map((task) => _TaskItem(
                      task: task,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: task.id),
                          ),
                        );
                        _loadData();
                      },
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ];
        }).toList()..removeLast(),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activity.take(10).length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final activity = _activity[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accentLight,
                  child: Text(
                    activity.actionIcon,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(
                  '${activity.staffName} ${activity.actionLabel} ${activity.taskTitle}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                subtitle: Text(
                  _formatDate(activity.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _TaskStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _TaskStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isOverdue;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isOverdue ? AppColors.destructive : AppColors.foreground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? AppColors.destructive : AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final ProjectTask task;
  final VoidCallback onTap;

  const _TaskItem({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: task.priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (task.assigneeName != null || task.dueDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (task.assigneeName != null) ...[
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.assigneeName!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.event_outlined,
                      size: 12,
                      color: task.isOverdue ? AppColors.destructive : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: task.isOverdue ? AppColors.destructive : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'normal';
  int? _assignedTo;
  DateTime? _dueDate;
  List<Staff> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await ApiService().getStaff();
      if (mounted) {
        setState(() {
          _staff = staff;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Task title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _assignedTo,
              decoration: const InputDecoration(labelText: 'Assign To'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Unassigned —')),
                ..._staff.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )),
              ],
              onChanged: (v) => setState(() => _assignedTo = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date'),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : '— Select —',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'title': _titleController.text.trim(),
              'description': _descController.text.trim(),
              'priority': _priority,
              'assignedTo': _assignedTo,
              'dueDate': _dueDate != null
                  ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                  : null,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
