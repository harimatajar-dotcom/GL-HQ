import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/constants.dart';
import '../models/staff.dart';
import '../providers/team_provider.dart';

class TeamEditScreen extends StatefulWidget {
  final Staff? staff;
  const TeamEditScreen({super.key, this.staff});

  @override
  State<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends State<TeamEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _telegramCtrl;
  String? _role;
  bool _saving = false;

  bool get _isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff?.name ?? '');
    _mobileCtrl = TextEditingController(text: widget.staff?.mobile ?? '');
    _pinCtrl = TextEditingController();
    _telegramCtrl = TextEditingController(text: widget.staff?.telegramId ?? '');
    _role = widget.staff?.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _telegramCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      Fluttertoast.showToast(msg: 'Please select a role');
      return;
    }

    setState(() => _saving = true);
    final team = context.read<TeamProvider>();
    final data = {
      'name': _nameCtrl.text.trim(),
      'role': _role,
      'mobile': _mobileCtrl.text.trim(),
      'telegram_id': _telegramCtrl.text.trim(),
    };

    if (_pinCtrl.text.isNotEmpty) {
      data['pin'] = _pinCtrl.text;
    }

    String? error;
    if (_isEdit) {
      data['id'] = widget.staff!.id.toString();
      error = await team.updateMember(data);
    } else {
      error = await team.addMember(data);
    }

    setState(() => _saving = false);
    if (error != null) {
      Fluttertoast.showToast(msg: error);
    } else {
      Fluttertoast.showToast(msg: _isEdit ? 'Member updated' : 'Member added');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Member', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete ${widget.staff!.name}? This action cannot be undone.'),
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
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final error = await context.read<TeamProvider>().deleteMember(widget.staff!.id);
    setState(() => _saving = false);

    if (error != null) {
      Fluttertoast.showToast(msg: error);
    } else {
      Fluttertoast.showToast(msg: 'Member deleted');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Member' : 'Add Member',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: GoogleFonts.poppins(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.poppins(),
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '9048333535',
                hintStyle: GoogleFonts.poppins(color: AppColors.mutedForeground.withValues(alpha: 0.5)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(
                labelText: 'Role *',
                labelStyle: GoogleFonts.poppins(),
              ),
              items: AppConstants.roleLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          '${AppConstants.roleEmojis[e.key]} ${e.value}',
                          style: GoogleFonts.poppins(),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _role = v),
              validator: (v) => v == null ? 'Role is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinCtrl,
              decoration: InputDecoration(
                labelText: '4-Digit PIN ${_isEdit ? "(leave blank to keep)" : "*"}',
                labelStyle: GoogleFonts.poppins(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              validator: (v) {
                if (!_isEdit && (v == null || v.isEmpty)) return 'PIN is required';
                if (v != null && v.isNotEmpty && v.length != 4) return 'PIN must be 4 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telegramCtrl,
              decoration: InputDecoration(
                labelText: 'Telegram ID (optional)',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'Update' : 'Add Member',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                  label: Text(
                    'Delete Member',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.destructive,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.destructive),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
