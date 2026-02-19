import 'package:flutter/material.dart';
import '../config/constants.dart';

class PriorityDot extends StatelessWidget {
  final String priority;
  const PriorityDot(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.priorityColor(priority),
      ),
    );
  }
}
