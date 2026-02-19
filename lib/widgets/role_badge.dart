import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.roleEmojis[role] ?? '👤';
    final label = AppConstants.roleLabels[role] ?? role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $label',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}
