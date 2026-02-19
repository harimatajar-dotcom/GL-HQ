import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';

class FilterBar extends StatelessWidget {
  final String? selectedStatus;
  final String? selectedPriority;
  final bool showPriorityFilter;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;

  const FilterBar({
    super.key,
    this.selectedStatus,
    this.selectedPriority,
    this.showPriorityFilter = false,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: selectedStatus == null,
                onSelected: () => onStatusChanged(null),
              ),
              _FilterChip(
                label: 'Pending',
                selected: selectedStatus == 'pending',
                onSelected: () => onStatusChanged('pending'),
              ),
              _FilterChip(
                label: 'In Progress',
                selected: selectedStatus == 'in_progress',
                onSelected: () => onStatusChanged('in_progress'),
              ),
              _FilterChip(
                label: 'Blocked',
                selected: selectedStatus == 'blocked',
                onSelected: () => onStatusChanged('blocked'),
              ),
              _FilterChip(
                label: 'Done',
                selected: selectedStatus == 'done',
                onSelected: () => onStatusChanged('done'),
              ),
            ],
          ),
        ),
        if (showPriorityFilter) ...[
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Priorities',
                  selected: selectedPriority == null,
                  onSelected: () => onPriorityChanged(null),
                ),
                _FilterChip(
                  label: '🔴 Urgent',
                  selected: selectedPriority == 'urgent',
                  onSelected: () => onPriorityChanged('urgent'),
                ),
                _FilterChip(
                  label: '🟡 High',
                  selected: selectedPriority == 'high',
                  onSelected: () => onPriorityChanged('high'),
                ),
                _FilterChip(
                  label: '🔵 Normal',
                  selected: selectedPriority == 'normal',
                  onSelected: () => onPriorityChanged('normal'),
                ),
                _FilterChip(
                  label: '⚪ Low',
                  selected: selectedPriority == 'low',
                  onSelected: () => onPriorityChanged('low'),
                ),
              ],
            ),
          ),
        ],
      ],
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
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.accentLight,
        checkmarkColor: AppColors.accent,
        showCheckmark: false,
      ),
    );
  }
}
