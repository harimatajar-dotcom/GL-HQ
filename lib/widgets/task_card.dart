import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../models/task.dart';
import '../utils/helpers.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool showAssignee;
  final VoidCallback? onDone;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.showAssignee = false,
    this.onDone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.priorityColor(task.priority),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    StatusBadge(task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showAssignee && task.assigneeName != null) ...[
                      Icon(Icons.person, size: 14, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        task.assigneeName!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: task.isOverdue ? AppColors.destructive : AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(task.dueDate!),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: task.isOverdue ? AppColors.destructive : AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(task.categoryEmoji, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (task.status != 'done')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onDone,
                      icon: const Icon(Icons.check, size: 16, color: AppColors.green),
                      label: Text(
                        'Done',
                        style: GoogleFonts.poppins(color: AppColors.green, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
