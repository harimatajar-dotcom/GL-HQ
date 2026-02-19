import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../models/report_field.dart';

class ReportFieldWidget extends StatelessWidget {
  final ReportField field;
  final TextEditingController controller;

  const ReportFieldWidget({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(field.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(field.label,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            if (field.type == FieldType.number)
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: UnderlineInputBorder()),
                  controller: controller,
                ),
              )
            else
              TextField(
                maxLines: 5,
                controller: controller,
                decoration: InputDecoration(
                  hintText: field.hint ?? 'Enter details...',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
            if (!field.required)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Optional — skip if not applicable',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
