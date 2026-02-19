import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/asset.dart';
import '../models/staff.dart';
import '../providers/auth_provider.dart';
import '../providers/asset_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'create_asset_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _asset;
  List<AssetAssignment> _assignments = [];
  List<AssetRepair> _repairs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssetDetail();
  }

  Future<void> _loadAssetDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService().getAssetDetail(widget.assetId);
      setState(() {
        _asset = result.asset;
        _assignments = result.assignments;
        _repairs = result.repairs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteAsset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Asset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to delete this asset permanently?'),
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

    if (confirm == true) {
      try {
        await context.read<AssetProvider>().deleteAsset(widget.assetId);
        if (mounted) {
          Fluttertoast.showToast(msg: 'Asset deleted');
          Navigator.pop(context);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to delete asset');
      }
    }
  }

  Future<void> _showAddRepairDialog() async {
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final issueController = TextEditingController();
    final costController = TextEditingController();
    final vendorController = TextEditingController();
    final notesController = TextEditingController();
    String status = 'pending';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Repair', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: issueController,
                decoration: const InputDecoration(labelText: 'Issue *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vendorController,
                decoration: const InputDecoration(labelText: 'Vendor'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (v) => status = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (issueController.text.isEmpty) {
                Fluttertoast.showToast(msg: 'Please enter an issue description');
                return;
              }

              try {
                await context.read<AssetProvider>().addRepair(
                  assetId: widget.assetId,
                  date: dateController.text,
                  issue: issueController.text,
                  cost: double.tryParse(costController.text),
                  vendor: vendorController.text.isEmpty ? null : vendorController.text,
                  status: status,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
                if (mounted) {
                  Fluttertoast.showToast(msg: 'Repair logged');
                  Navigator.pop(ctx);
                  _loadAssetDetail();
                }
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to log repair');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog() async {
    final staff = await ApiService().getStaff();
    int? selectedStaffId = _asset?.assignedTo;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Asset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: DropdownButtonFormField<int?>(
          value: selectedStaffId,
          decoration: const InputDecoration(labelText: 'Assign To'),
          items: [
            const DropdownMenuItem(value: null, child: Text('— Unassigned —')),
            ...staff.map((s) => DropdownMenuItem(
              value: s.id,
              child: Text('${s.name} (${s.roleLabel})'),
            )),
          ],
          onChanged: (v) => selectedStaffId = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AssetProvider>().assignAsset(
                  widget.assetId,
                  selectedStaffId,
                );
                if (mounted) {
                  Fluttertoast.showToast(msg: 'Asset assigned');
                  Navigator.pop(ctx);
                  _loadAssetDetail();
                }
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to assign asset');
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin || auth.role == 'finance';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _asset?.name ?? 'Asset Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isAdmin && _asset != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateAssetScreen(asset: _asset),
                      ),
                    );
                    _loadAssetDetail();
                    break;
                  case 'assign':
                    await _showAssignDialog();
                    break;
                  case 'repair':
                    await _showAddRepairDialog();
                    break;
                  case 'delete':
                    await _deleteAsset();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'assign', child: Text('Assign to Staff')),
                const PopupMenuItem(value: 'repair', child: Text('Log Repair')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.destructive))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const SkeletonList()
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error loading asset',
                  subtitle: _error!,
                )
              : _asset == null
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Asset not found',
                      subtitle: 'The asset may have been deleted',
                    )
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: _loadAssetDetail,
                      child: CustomScrollView(
                        slivers: [
                          // Header with tags
                          SliverToBoxAdapter(
                            child: _buildHeader(context),
                          ),

                          // Key Information Grid
                          SliverToBoxAdapter(
                            child: _buildInfoGrid(context),
                          ),

                          // Remarks Section
                          if (_asset!.remarks != null && _asset!.remarks!.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildRemarksCard(context),
                            ),

                          // Notes Section
                          if (_asset!.notes != null && _asset!.notes!.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildNotesCard(context),
                            ),

                          // Assignment History
                          SliverToBoxAdapter(
                            child: _buildAssignmentsSection(context),
                          ),

                          // Repair History
                          SliverToBoxAdapter(
                            child: _buildRepairsSection(context),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final statusColor = Asset.statusColor(_asset!.status);
    final statusBgColor = Asset.statusBgColor(_asset!.status);
    final statusLabel = Asset.statusLabel(_asset!.status);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_asset!.assetTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _asset!.assetTag!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _asset!.type[0].toUpperCase() + _asset!.type.substring(1),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (_asset!.warrantyExpiry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _asset!.isWarrantyExpired
                        ? AppColors.destructive.withOpacity(0.1)
                        : AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _asset!.isWarrantyExpired ? 'Warranty Expired' : 'Warranty Active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _asset!.isWarrantyExpired
                          ? AppColors.destructive
                          : AppColors.green,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    final items = [
      _InfoItem('Brand', _asset!.brand ?? '—'),
      _InfoItem('Model', _asset!.model ?? '—'),
      _InfoItem('Serial #', _asset!.serialNumber ?? '—'),
      _InfoItem('Assigned To', _asset!.ownerName ?? 'Unassigned'),
      _InfoItem('Purchase Date', _asset!.purchaseDate ?? '—'),
      _InfoItem('Purchase Price', _asset!.purchasePrice != null
          ? '₹${_asset!.purchasePrice!.toStringAsFixed(2)}'
          : '—'),
      _InfoItem('Vendor', _asset!.vendor ?? '—'),
      _InfoItem('Age', _asset!.age),
      _InfoItem('Warranty Expiry', _asset!.warrantyExpiry ?? '—'),
      _InfoItem('Last Checkup', _asset!.lastCheckup ?? 'Never'),
      _InfoItem(
        'Next Checkup',
        _asset!.nextCheckup ?? '—',
        isWarning: _asset!.isCheckupDue,
      ),
      _InfoItem('Checkup Interval', '${_asset!.checkupInterval ?? 90} days'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _buildInfoItem(items[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(_InfoItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: item.isWarning ? AppColors.destructive : AppColors.foreground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRemarksCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: AppColors.amber.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Remarks',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _asset!.remarks!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.foreground,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _asset!.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.foreground,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assignment History',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_assignments.isEmpty)
                Text(
                  'No assignment history',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                )
              else
                ..._assignments.map((a) => _buildAssignmentItem(a)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentItem(AssetAssignment assignment) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              assignment.staffName ?? '—',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              assignment.assignedAt,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              assignment.returnedAt ?? '—',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              assignment.duration,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: assignment.isCurrent ? AppColors.accent : AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairsSection(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.isAdmin || auth.role == 'finance';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repair History',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: _showAddRepairDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Repair'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_repairs.isEmpty)
                Text(
                  'No repairs logged',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                )
              else
                ..._repairs.map((r) => _buildRepairItem(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepairItem(AssetRepair repair) {
    final statusColor = AssetRepair.statusColor(repair.status);
    final statusBgColor = AssetRepair.statusBgColor(repair.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  repair.issue,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  repair.status[0].toUpperCase() + repair.status.substring(1),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                repair.date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              if (repair.cost != null && repair.cost! > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.currency_rupee, size: 12, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  repair.cost!.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
              if (repair.vendor != null && repair.vendor!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(Icons.store, size: 12, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  repair.vendor!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          if (repair.notes != null && repair.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              repair.notes!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isWarning;

  _InfoItem(this.label, this.value, {this.isWarning = false});
}
