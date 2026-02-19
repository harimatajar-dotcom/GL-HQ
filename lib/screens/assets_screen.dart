import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/asset.dart';
import '../providers/auth_provider.dart';
import '../providers/asset_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'asset_detail_screen.dart';
import 'create_asset_screen.dart';
import 'home_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().refresh();
      final auth = context.read<AuthProvider>();
      if (auth.staffId != null) {
        context.read<AssetProvider>().loadMyAssets(auth.staffId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AssetProvider>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AssetProvider>().setSearch(query.isEmpty ? null : query);
    });
  }

  Future<void> _refresh() async {
    await context.read<AssetProvider>().refresh();
    final auth = context.read<AuthProvider>();
    if (auth.staffId != null) {
      await context.read<AssetProvider>().loadMyAssets(auth.staffId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final assets = context.watch<AssetProvider>();
    final isAdmin = auth.isAdmin || auth.role == 'finance';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context
              .findAncestorStateOfType<HomeScreenState>()
              ?.scaffoldKey
              .currentState
              ?.openDrawer(),
        ),
        title: Text('Assets', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAssetScreen()),
                );
                if (mounted) _refresh();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // My Assets Section
            if (!isAdmin || assets.myAssets.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildMyAssetsSection(context, assets, auth),
              ),

            // Search and Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search assets...',
                    hintStyle: GoogleFonts.poppins(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              assets.setSearch(null);
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            // Status Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: assets.statusFilter == null,
                      onSelected: () => assets.setStatusFilter(null),
                    ),
                    _FilterChip(
                      label: 'Available',
                      selected: assets.statusFilter == 'active',
                      color: AppColors.green,
                      onSelected: () => assets.setStatusFilter('active'),
                    ),
                    _FilterChip(
                      label: 'In Repair',
                      selected: assets.statusFilter == 'in_repair',
                      color: AppColors.amber,
                      onSelected: () => assets.setStatusFilter('in_repair'),
                    ),
                    _FilterChip(
                      label: 'Retired',
                      selected: assets.statusFilter == 'retired',
                      color: AppColors.slate,
                      onSelected: () => assets.setStatusFilter('retired'),
                    ),
                    _FilterChip(
                      label: 'Lost',
                      selected: assets.statusFilter == 'lost',
                      color: AppColors.destructive,
                      onSelected: () => assets.setStatusFilter('lost'),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Types',
                      selected: assets.categoryFilter == null,
                      onSelected: () => assets.setCategoryFilter(null),
                    ),
                    ...Asset.types.map((type) => _FilterChip(
                      label: type[0].toUpperCase() + type.substring(1),
                      selected: assets.categoryFilter == type,
                      onSelected: () => assets.setCategoryFilter(type),
                    )),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Assets List
            if (assets.loading && assets.assets.isEmpty)
              const SliverToBoxAdapter(child: SkeletonList())
            else if (assets.assets.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No assets found',
                  subtitle: 'Assets will appear here when added',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == assets.assets.length) {
                      return assets.hasMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                    final asset = assets.assets[index];
                    return _AssetCard(
                      asset: asset,
                      onTap: () => _navigateToDetail(context, asset),
                    );
                  },
                  childCount: assets.assets.length + (assets.hasMore ? 1 : 0),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'assets_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAssetScreen()),
                );
                if (mounted) _refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMyAssetsSection(BuildContext context, AssetProvider assets, AuthProvider auth) {
    if (assets.myAssetsLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (assets.myAssets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'My Assets (${assets.myAssets.length})',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...assets.myAssets.take(3).map((asset) => _MyAssetItem(
            asset: asset,
            onTap: () => _navigateToDetail(context, asset),
          )),
          if (assets.myAssets.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${assets.myAssets.length - 3} more',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, Asset asset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AssetDetailScreen(assetId: asset.id)),
    );
    if (mounted) _refresh();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? (color ?? AppColors.accent) : AppColors.foreground,
          ),
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color?.withValues(alpha: 0.15) ?? AppColors.accentLight,
        backgroundColor: AppColors.muted,
        checkmarkColor: color ?? AppColors.accent,
        showCheckmark: false,
        side: BorderSide(
          color: selected ? (color ?? AppColors.accent) : AppColors.border,
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const _AssetCard({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Asset.statusColor(asset.status);
    final statusBgColor = Asset.statusBgColor(asset.status);
    final statusLabel = Asset.statusLabel(asset.status);

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
                    if (asset.assetTag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          asset.assetTag!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        asset.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      asset.type[0].toUpperCase() + asset.type.substring(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (asset.ownerName != null) ...[
                      Icon(Icons.person, size: 14, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        asset.ownerName!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.person_outline, size: 14, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        'Unassigned',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (asset.isWarrantyExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Warranty Expired',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.destructive,
                          ),
                        ),
                      )
                    else if (asset.isCheckupDue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Checkup Due',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyAssetItem extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const _MyAssetItem({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Asset.statusColor(asset.status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${asset.type[0].toUpperCase() + asset.type.substring(1)} · ${asset.assetTag ?? "No Tag"}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
