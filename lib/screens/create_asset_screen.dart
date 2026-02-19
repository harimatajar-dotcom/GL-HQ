import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/asset.dart';
import '../models/staff.dart';
import '../providers/asset_provider.dart';
import '../services/api_service.dart';

class CreateAssetScreen extends StatefulWidget {
  final Asset? asset;

  const CreateAssetScreen({super.key, this.asset});

  @override
  State<CreateAssetScreen> createState() => _CreateAssetScreenState();
}

class _CreateAssetScreenState extends State<CreateAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _vendorController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _remarksController = TextEditingController();
  final _checkupIntervalController = TextEditingController(text: '90');

  String _type = 'laptop';
  String _status = 'active';
  int? _assignedTo;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;

  List<Staff> _staffList = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();

    if (widget.asset != null) {
      _nameController.text = widget.asset!.name;
      _brandController.text = widget.asset!.brand ?? '';
      _modelController.text = widget.asset!.model ?? '';
      _serialController.text = widget.asset!.serialNumber ?? '';
      _vendorController.text = widget.asset!.vendor ?? '';
      _priceController.text = widget.asset!.purchasePrice?.toString() ?? '';
      _notesController.text = widget.asset!.notes ?? '';
      _remarksController.text = widget.asset!.remarks ?? '';
      _checkupIntervalController.text = widget.asset!.checkupInterval?.toString() ?? '90';
      _type = widget.asset!.type;
      _status = widget.asset!.status;
      _assignedTo = widget.asset!.assignedTo;

      if (widget.asset!.purchaseDate != null) {
        _purchaseDate = DateTime.tryParse(widget.asset!.purchaseDate!);
      }
      if (widget.asset!.warrantyExpiry != null) {
        _warrantyExpiry = DateTime.tryParse(widget.asset!.warrantyExpiry!);
      }
    }
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      _staffList = await ApiService().getStaff();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load staff');
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (widget.asset == null) {
        // Create new asset
        await context.read<AssetProvider>().addAsset(
          name: _nameController.text.trim(),
          type: _type,
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          purchaseDate: _purchaseDate?.toIso8601String().split('T')[0],
          purchasePrice: _priceController.text.isEmpty
              ? null
              : double.tryParse(_priceController.text),
          vendor: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
          assignedTo: _assignedTo,
          status: _status,
          warrantyExpiry: _warrantyExpiry?.toIso8601String().split('T')[0],
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          checkupInterval: int.tryParse(_checkupIntervalController.text) ?? 90,
        );
        if (mounted) {
          Fluttertoast.showToast(msg: 'Asset created successfully');
          Navigator.pop(context);
        }
      } else {
        // Update existing asset
        await context.read<AssetProvider>().updateAsset(
          widget.asset!.id,
          name: _nameController.text.trim(),
          type: _type,
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          purchaseDate: _purchaseDate?.toIso8601String().split('T')[0],
          purchasePrice: _priceController.text.isEmpty
              ? null
              : double.tryParse(_priceController.text),
          vendor: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
          assignedTo: _assignedTo,
          status: _status,
          warrantyExpiry: _warrantyExpiry?.toIso8601String().split('T')[0],
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          checkupInterval: int.tryParse(_checkupIntervalController.text) ?? 90,
        );
        if (mounted) {
          Fluttertoast.showToast(msg: 'Asset updated successfully');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save asset: $e');
    }

    setState(() => _saving = false);
  }

  Future<void> _selectDate(bool isPurchase) async {
    final initial = isPurchase ? _purchaseDate : _warrantyExpiry;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = date;
        } else {
          _warrantyExpiry = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.asset != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Asset' : 'Add Asset',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Information
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Name *',
                      hintText: 'e.g., MacBook Pro 16"',
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: Asset.types.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1)),
                    )).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            hintText: 'e.g., Apple',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            hintText: 'e.g., MacBook Pro',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                      hintText: 'e.g., C02XYZ123',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Purchase Information
                  _buildSectionTitle('Purchase Information'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Purchase Date',
                            ),
                            child: Text(
                              _purchaseDate != null
                                  ? _purchaseDate!.toIso8601String().split('T')[0]
                                  : 'Select date',
                              style: GoogleFonts.poppins(
                                color: _purchaseDate != null
                                    ? AppColors.foreground
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Warranty Expiry',
                            ),
                            child: Text(
                              _warrantyExpiry != null
                                  ? _warrantyExpiry!.toIso8601String().split('T')[0]
                                  : 'Select date',
                              style: GoogleFonts.poppins(
                                color: _warrantyExpiry != null
                                    ? AppColors.foreground
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (₹)',
                            prefixText: '₹ ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _vendorController,
                          decoration: const InputDecoration(
                            labelText: 'Vendor',
                            hintText: 'e.g., Amazon',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Assignment & Status
                  _buildSectionTitle('Assignment & Status'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _assignedTo,
                          decoration: const InputDecoration(labelText: 'Assigned To'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('— Unassigned —'),
                            ),
                            ..._staffList.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.roleLabel})'),
                            )),
                          ],
                          onChanged: (v) => setState(() => _assignedTo = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status *'),
                          items: Asset.statuses.map((s) {
                            final label = Asset.statusLabel(s);
                            return DropdownMenuItem(
                              value: s,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _checkupIntervalController,
                    decoration: const InputDecoration(
                      labelText: 'Checkup Interval (days)',
                      helperText: 'How often this asset should be inspected',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Notes & Remarks
                  _buildSectionTitle('Notes & Remarks'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      hintText: 'Any issues, damage, or special notes...',
                      helperText: 'Visible as warnings in asset list',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'General Notes',
                      hintText: 'Additional information about this asset...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Asset' : 'Create Asset',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }
}
