import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/tasks_provider.dart';
import '../services/api_service.dart';
import '../widgets/task_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';
import 'home_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<TasksProvider>().refresh(staffId: auth.staffId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TasksProvider>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<TasksProvider>().setSearch(query.isEmpty ? null : query);
    });
  }

  Future<void> _markDone(task) async {
    try {
      await ApiService().updateTask(task.id, {'status': 'done'});
      if (mounted) {
        final auth = context.read<AuthProvider>();
        context.read<TasksProvider>().refresh(staffId: auth.staffId);
        Fluttertoast.showToast(msg: 'Task marked as done');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update task');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TasksProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Tasks', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('My')),
                  ButtonSegment(value: true, label: Text('All')),
                ],
                selected: {tasks.showAllTasks},
                onSelectionChanged: (v) => tasks.toggleAllTasks(),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.accentLight,
                  selectedForegroundColor: AppColors.foreground,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search tasks...',
                hintStyle: GoogleFonts.poppins(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Status filter chips — full-width scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: tasks.statusFilter == null,
                  onSelected: () => tasks.setStatusFilter(null),
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: tasks.statusFilter == 'pending',
                  onSelected: () => tasks.setStatusFilter('pending'),
                ),
                _FilterChip(
                  label: 'In Progress',
                  selected: tasks.statusFilter == 'in_progress',
                  onSelected: () => tasks.setStatusFilter('in_progress'),
                ),
                _FilterChip(
                  label: 'Blocked',
                  selected: tasks.statusFilter == 'blocked',
                  onSelected: () => tasks.setStatusFilter('blocked'),
                ),
                _FilterChip(
                  label: 'Done',
                  selected: tasks.statusFilter == 'done',
                  onSelected: () => tasks.setStatusFilter('done'),
                ),
              ],
            ),
          ),
          if (isAdmin && tasks.showAllTasks)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Priorities',
                      selected: tasks.priorityFilter == null,
                      onSelected: () => tasks.setPriorityFilter(null),
                    ),
                    _FilterChip(
                      label: '🔴 Urgent',
                      selected: tasks.priorityFilter == 'urgent',
                      onSelected: () => tasks.setPriorityFilter('urgent'),
                    ),
                    _FilterChip(
                      label: '🟡 High',
                      selected: tasks.priorityFilter == 'high',
                      onSelected: () => tasks.setPriorityFilter('high'),
                    ),
                    _FilterChip(
                      label: '🔵 Normal',
                      selected: tasks.priorityFilter == 'normal',
                      onSelected: () => tasks.setPriorityFilter('normal'),
                    ),
                    _FilterChip(
                      label: '⚪ Low',
                      selected: tasks.priorityFilter == 'low',
                      onSelected: () => tasks.setPriorityFilter('low'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Task list
          Expanded(
            child: tasks.loading && tasks.tasks.isEmpty
                ? const SkeletonList()
                : tasks.tasks.isEmpty
                    ? const EmptyState(
                        icon: Icons.task_alt,
                        title: 'No tasks found',
                        subtitle: 'Tasks will appear here when created',
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () => tasks.refresh(staffId: auth.staffId),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: tasks.tasks.length + (tasks.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == tasks.tasks.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final task = tasks.tasks[i];
                            return TaskCard(
                              task: task,
                              showAssignee: isAdmin && tasks.showAllTasks,
                              onDone: () => _markDone(task),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailScreen(taskId: task.id),
                                  ),
                                );
                                if (mounted) {
                                  context.read<TasksProvider>().refresh(staffId: auth.staffId);
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'tasks_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
                if (mounted) {
                  context.read<TasksProvider>().refresh(staffId: auth.staffId);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.accent : AppColors.foreground,
          ),
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.accentLight,
        backgroundColor: AppColors.muted,
        checkmarkColor: AppColors.accent,
        showCheckmark: false,
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
        ),
      ),
    );
  }
}
