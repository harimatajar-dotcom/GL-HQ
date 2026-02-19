import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../utils/helpers.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ').capitalize();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.statusColor(status),
        ),
      ),
    );
  }
}
