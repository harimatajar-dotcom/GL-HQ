import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/touchpoint_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';

class TouchpointScreen extends StatefulWidget {
  const TouchpointScreen({super.key});

  @override
  State<TouchpointScreen> createState() => _TouchpointScreenState();
}

class _TouchpointScreenState extends State<TouchpointScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TouchpointProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TouchpointProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text('TouchPoint', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tp.refreshAll(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.mutedForeground,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _CustomersTab(),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TouchpointProvider>();
    final dashboard = tp.dashboard;

    if (tp.loading && dashboard == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
          ],
        ),
      );
    }

    if (dashboard == null) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No data available',
        subtitle: 'Pull to refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () => tp.loadDashboard(),
      color: AppColors.accent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Overdue',
                    value: dashboard.overdue.toString(),
                    icon: Icons.warning_amber,
                    color: AppColors.destructive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Today',
                    value: dashboard.today.toString(),
                    icon: Icons.today,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Upcoming',
                    value: dashboard.upcoming.toString(),
                    icon: Icons.event,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'This Week',
                    value: dashboard.completedWeek.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Health Distribution
            _SectionCard(
              title: 'Customer Health',
              icon: Icons.favorite_outline,
              child: _buildHealthChart(dashboard.health),
            ),
            const SizedBox(height: 16),

            // Renewal Pipeline
            if (dashboard.renewals.isNotEmpty)
              _SectionCard(
                title: 'Renewal Pipeline',
                icon: Icons.update,
                child: _buildRenewalList(dashboard.renewals),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthChart(Map<String, int> health) {
    final total = health.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No health data available'),
        ),
      );
    }

    final data = [
      {'label': 'Healthy', 'value': health['healthy'] ?? 0, 'color': AppColors.green, 'bg': const Color(0xFFD1FAE5)},
      {'label': 'At Risk', 'value': health['at_risk'] ?? 0, 'color': AppColors.amber, 'bg': const Color(0xFFFEF3C7)},
      {'label': 'Critical', 'value': health['critical'] ?? 0, 'color': AppColors.destructive, 'bg': const Color(0xFFFEE2E2)},
      {'label': 'Unknown', 'value': health['unknown'] ?? 0, 'color': AppColors.slate, 'bg': AppColors.muted},
    ];

    return Column(
      children: data.map((item) {
        final value = item['value'] as int;
        final percent = total > 0 ? (value / total * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                alignment: Alignment.centerRight,
                child: Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRenewalList(List<Map<String, dynamic>> renewals) {
    return Column(
      children: renewals.take(5).map((r) {
        final week = r['week'] as String? ?? 'Unknown';
        final count = r['count'] ?? 0;
        final revenue = r['revenue'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  week,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count customers',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${NumberFormat.compact().format(revenue)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CustomersTab extends StatefulWidget {
  const _CustomersTab();

  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TouchpointProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TouchpointProvider>();
    final customers = tp.customers;

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search customers...',
              hintStyle: GoogleFonts.poppins(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        tp.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: tp.setSearchQuery,
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: tp.filterStatus.isEmpty,
                onSelected: () => tp.setStatusFilter(''),
              ),
              _FilterChip(
                label: 'Healthy',
                selected: tp.filterStatus == 'healthy',
                onSelected: () => tp.setStatusFilter('healthy'),
                color: AppColors.green,
              ),
              _FilterChip(
                label: 'At Risk',
                selected: tp.filterStatus == 'at_risk',
                onSelected: () => tp.setStatusFilter('at_risk'),
                color: AppColors.amber,
              ),
              _FilterChip(
                label: 'Critical',
                selected: tp.filterStatus == 'critical',
                onSelected: () => tp.setStatusFilter('critical'),
                color: AppColors.destructive,
              ),
              _FilterChip(
                label: 'Trial',
                selected: tp.filterSubscription.contains('trial'),
                onSelected: () => tp.setSubscriptionFilter(
                  tp.filterSubscription.isEmpty ? 'free_trial' : '',
                ),
                color: AppColors.blue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Customer List
        Expanded(
          child: tp.loading && customers.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(),
                  ),
                )
              : customers.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No customers found',
                      subtitle: 'Try changing your search or filters',
                    )
                  : RefreshIndicator(
                      onRefresh: () => tp.loadCustomers(),
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _CustomerCard(customer: customer);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final dynamic customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer as dynamic;
    
    Color healthColor;
    switch (c.health) {
      case 'healthy':
        healthColor = AppColors.green;
        break;
      case 'at_risk':
        healthColor = AppColors.amber;
        break;
      case 'critical':
      case 'churning':
        healthColor = AppColors.destructive;
        break;
      default:
        healthColor = AppColors.slate;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (c.company != null)
                      Text(
                        c.company,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c.healthLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(
                c.subscriptionLabel,
                c.isTrial ? AppColors.blue : AppColors.teal,
              ),
              const SizedBox(width: 8),
              _buildTag(
                c.daysUntilExpiry >= 0
                    ? '${c.daysUntilExpiry}d left'
                    : '${c.daysUntilExpiry.abs()}d overdue',
                c.daysUntilExpiry > 7 ? AppColors.green : 
                c.daysUntilExpiry >= 0 ? AppColors.amber : AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              _ActionButton(
                icon: Icons.phone,
                onTap: () => _copyToClipboard(context, c.phone, 'Phone number copied'),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.message,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.calendar_today,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.foreground,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: AppColors.foreground),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
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
    final chipColor = color ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? chipColor.withOpacity(0.15) : AppColors.muted,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? chipColor : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
