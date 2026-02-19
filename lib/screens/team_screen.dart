import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/constants.dart';
import '../providers/team_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'team_edit_screen.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadTeam();
    });
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Team', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: team.loading && team.teamList.isEmpty
          ? const SkeletonList()
          : team.teamList.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No team members',
                  subtitle: 'Add team members to get started',
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => team.loadTeam(),
                  child: ListView.builder(
                    itemCount: team.teamList.length,
                    itemBuilder: (_, i) {
                      final s = team.teamList[i];
                      return Dismissible(
                        key: ValueKey(s.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.destructive,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Delete Member', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              content: Text('Delete ${s.name}? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.destructive))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final error = await team.deleteMember(s.id);
                            if (error != null) {
                              Fluttertoast.showToast(msg: error);
                              return false;
                            }
                            return true;
                          }
                          return false;
                        },
                        child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s.active ? AppColors.accentLight : AppColors.muted,
                          child: Text(s.emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(
                          s.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            decoration: s.active ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          '${s.label}${s.mobile != null && s.mobile!.isNotEmpty ? ' • ${s.mobile}' : ''} • ${s.activeTasks ?? 0} tasks',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: s.active,
                              activeColor: AppColors.accent,
                              onChanged: (_) async {
                                final error = await team.toggleMember(s.id);
                                if (error != null) {
                                  Fluttertoast.showToast(msg: error);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamEditScreen(staff: s),
                                  ),
                                );
                                if (mounted) team.loadTeam();
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamEditScreen(staff: s),
                            ),
                          );
                          if (mounted) team.loadTeam();
                        },
                      ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'team_fab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeamEditScreen()),
          );
          if (mounted) context.read<TeamProvider>().loadTeam();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
