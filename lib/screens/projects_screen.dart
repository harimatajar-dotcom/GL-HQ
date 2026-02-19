import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../models/project.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _showBoard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    final provider = context.read<ProjectsProvider>();
    if (_showBoard) {
      provider.loadBoard();
    } else {
      provider.refresh();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProjectsProvider>().setSearch(query.isEmpty ? null : query);
    });
  }

  void _toggleView() {
    setState(() {
      _showBoard = !_showBoard;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final projects = context.watch<ProjectsProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('Projects', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          // View toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('List')),
                ButtonSegment(value: true, label: Text('Board')),
              ],
              selected: {_showBoard},
              onSelectionChanged: (_) => _toggleView(),
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
                hintText: 'Search projects...',
                hintStyle: GoogleFonts.poppins(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: projects.statusFilter == null,
                  onSelected: () => projects.setStatusFilter(null),
                ),
                _FilterChip(
                  label: 'Active',
                  selected: projects.statusFilter == 'active',
                  onSelected: () => projects.setStatusFilter('active'),
                  color: AppColors.teal,
                ),
                _FilterChip(
                  label: 'On Hold',
                  selected: projects.statusFilter == 'on_hold',
                  onSelected: () => projects.setStatusFilter('on_hold'),
                  color: AppColors.amber,
                ),
                _FilterChip(
                  label: 'Completed',
                  selected: projects.statusFilter == 'completed',
                  onSelected: () => projects.setStatusFilter('completed'),
                  color: AppColors.green,
                ),
                _FilterChip(
                  label: 'Archived',
                  selected: projects.statusFilter == 'archived',
                  onSelected: () => projects.setStatusFilter('archived'),
                  color: AppColors.slate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // KPI Cards
          if (!_showBoard)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _KpiCard(
                    label: 'Total',
                    value: projects.totalProjects.toString(),
                    flex: 1,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'Active',
                    value: projects.activeCount.toString(),
                    color: AppColors.teal,
                    flex: 1,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'On Hold',
                    value: projects.onHoldCount.toString(),
                    color: AppColors.amber,
                    flex: 1,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'Done',
                    value: projects.completedCount.toString(),
                    color: AppColors.green,
                    flex: 1,
                  ),
                ],
              ),
            ),
          if (!_showBoard) const SizedBox(height: 16),
          // Content
          Expanded(
            child: _showBoard
                ? _buildBoardView(projects, isAdmin)
                : _buildListView(projects, isAdmin),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'projects_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
                );
                if (mounted) {
                  context.read<ProjectsProvider>().refresh();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListView(ProjectsProvider projects, bool isAdmin) {
    if (projects.loading && projects.projects.isEmpty) {
      return const SkeletonList();
    }

    if (projects.projects.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No projects found',
        subtitle: 'Projects will appear here when created',
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => projects.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: projects.projects.length,
        itemBuilder: (_, i) {
          final project = projects.projects[i];
          return _ProjectCard(
            project: project,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(projectId: project.id),
                ),
              );
              if (mounted) {
                projects.refresh();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBoardView(ProjectsProvider projects, bool isAdmin) {
    if (projects.boardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => projects.loadBoard(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KanbanColumn(
              title: 'Active',
              status: 'active',
              color: AppColors.teal,
              projects: projects.board['active'] ?? [],
              onMove: isAdmin
                  ? (projectId, newStatus) => projects.moveProject(projectId, newStatus)
                  : null,
              onTapProject: (project) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
                if (mounted) {
                  projects.loadBoard();
                }
              },
            ),
            const SizedBox(width: 12),
            _KanbanColumn(
              title: 'On Hold',
              status: 'on_hold',
              color: AppColors.amber,
              projects: projects.board['on_hold'] ?? [],
              onMove: isAdmin
                  ? (projectId, newStatus) => projects.moveProject(projectId, newStatus)
                  : null,
              onTapProject: (project) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
                if (mounted) {
                  projects.loadBoard();
                }
              },
            ),
            const SizedBox(width: 12),
            _KanbanColumn(
              title: 'Completed',
              status: 'completed',
              color: AppColors.green,
              projects: projects.board['completed'] ?? [],
              onMove: isAdmin
                  ? (projectId, newStatus) => projects.moveProject(projectId, newStatus)
                  : null,
              onTapProject: (project) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
                if (mounted) {
                  projects.loadBoard();
                }
              },
            ),
            const SizedBox(width: 12),
            _KanbanColumn(
              title: 'Archived',
              status: 'archived',
              color: AppColors.slate,
              projects: projects.board['archived'] ?? [],
              onMove: isAdmin
                  ? (projectId, newStatus) => projects.moveProject(projectId, newStatus)
                  : null,
              onTapProject: (project) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                );
                if (mounted) {
                  projects.loadBoard();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
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
            color: selected ? (color ?? AppColors.accent) : AppColors.foreground,
          ),
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color?.withOpacity(0.15) ?? AppColors.accentLight,
        backgroundColor: AppColors.muted,
        checkmarkColor: color ?? AppColors.accent,
        showCheckmark: false,
        side: BorderSide(
          color: selected ? (color ?? AppColors.accent) : AppColors.border,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final int flex;

  const _KpiCard({
    required this.label,
    required this.value,
    this.color,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? AppColors.muted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.foreground,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: project.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      project.statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: project.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progressPercent / 100,
                            backgroundColor: AppColors.muted,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              project.isOverdue ? AppColors.destructive : AppColors.teal,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.doneTasks}/${project.totalTasks} tasks • ${project.progressPercent}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (project.leadName != null) ...[
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.leadName!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (project.isOverdue) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.destructive,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Overdue',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final String status;
  final Color color;
  final List<Project> projects;
  final Future<bool> Function(int, String)? onMove;
  final void Function(Project) onTapProject;

  const _KanbanColumn({
    required this.title,
    required this.status,
    required this.color,
    required this.projects,
    this.onMove,
    required this.onTapProject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                    projects.length.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 280,
            ),
            child: DragTarget<int>(
              onWillAccept: (_) => onMove != null,
              onAccept: (projectId) async {
                if (onMove != null) {
                  final success = await onMove!(projectId, status);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Project moved to $title'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (_, i) {
                    final project = projects[i];
                    return _KanbanCard(
                      project: project,
                      onTap: () => onTapProject(project),
                      onDragStarted: onMove != null ? () {} : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onDragStarted;

  const _KanbanCard({
    required this.project,
    required this.onTap,
    this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progressPercent / 100,
                        backgroundColor: AppColors.muted,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${project.progressPercent}%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.task_alt_outlined,
                    size: 12,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${project.doneTasks}/${project.totalTasks}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  if (project.leadName != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.leadName!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDragStarted == null) {
      return card;
    }

    return Draggable<int>(
      data: project.id,
      onDragStarted: onDragStarted,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 256,
          child: card,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: card,
      ),
      child: card,
    );
  }
}
