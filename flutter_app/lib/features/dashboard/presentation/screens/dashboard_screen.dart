import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';

// ─── Providers ──────────────────────────────────────────────────────
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboard);
  return response.data['stats'] as Map<String, dynamic>;
});

final lowStockProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardLowStock);
  return response.data as List<dynamic>;
});

final recentSalesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardRecentSales);
  return response.data as List<dynamic>;
});

final recentPurchasesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardRecentPurchases);
  return response.data as List<dynamic>;
});

final dailySalesChartProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardDailySales);
  return response.data as List<dynamic>;
});

final dailyPurchasesChartProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardDailyPurchases);
  return response.data as List<dynamic>;
});

final topProductsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.dashboardTopProducts);
  return response.data as List<dynamic>;
});

final expiringSoonProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryNearExpiry, queryParams: {'days': '30'});
  return response.data as List<dynamic>;
});

// ─── Dashboard Screen ───────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  void _invalidateAll() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(lowStockProvider);
    ref.invalidate(recentSalesProvider);
    ref.invalidate(recentPurchasesProvider);
    ref.invalidate(dailySalesChartProvider);
    ref.invalidate(dailyPurchasesChartProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(expiringSoonProvider);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _DashboardAppBar(
          selectedDate: _selectedDate,
          onRefresh: _invalidateAll,
          onDateTap: _pickDate,
        ),
      ),
      body: dashboardAsync.when(
        loading: () => const AppLoading(message: 'Loading dashboard...'),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => _invalidateAll(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1100;
              final isTablet = constraints.maxWidth > 700;
              final isMobile = !isTablet;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mobile date chip
                    if (isMobile) ...[_MobileDateChip(date: _selectedDate, onTap: _pickDate), const SizedBox(height: 12)],

                    // Stats Grid (matches design: 2-col mobile, 4-col desktop)
                    _StatsGrid(stats: stats, isMobile: isMobile),
                    SizedBox(height: isMobile ? 16 : 24),

                    // Charts
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 3, child: _SalesChart()),
                          const SizedBox(width: 20),
                          const Expanded(flex: 3, child: _PurchaseChart()),
                        ],
                      )
                    else ...[const _SalesChart(), const SizedBox(height: 16), const _PurchaseChart()],
                    SizedBox(height: isMobile ? 16 : 24),

                    // Desktop: stock left, alerts+products right  |  Mobile: stacked
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 5, child: _StockOverview()),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: Column(children: [
                              _AlertsPanel(stats: stats),
                              const SizedBox(height: 20),
                              const _TopProducts(),
                            ]),
                          ),
                        ],
                      )
                    else ...[_AlertsPanel(stats: stats), const SizedBox(height: 16), const _TopProducts()],
                    SizedBox(height: isMobile ? 16 : 24),

                    // Recent Transactions
                    const _RecentTransactions(),

                    // Mobile Quick Actions bar
                    if (isMobile) ...[const SizedBox(height: 16), const _QuickActions()],

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard AppBar ───────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onRefresh;
  final VoidCallback onDateTap;
  const _DashboardAppBar({required this.selectedDate, required this.onRefresh, required this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
    final isWide = MediaQuery.of(context).size.width > 700;

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.bg,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          )),
          Text('Welcome back, Owner 👋', style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
          )),
        ],
      ),
      actions: [
        if (isWide) ...[  
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(dateStr, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
                )),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/sales/add'),
            icon: const Icon(Icons.point_of_sale, size: 16),
            label: Text('POS', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          Positioned(
            right: 8, top: 8,
            child: Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile Date Chip ────────────────────────────────────────────────
class _MobileDateChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _MobileDateChip({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(DateFormat('dd MMM yyyy').format(date), style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
          )),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}


// ─── Stats Grid ──────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isMobile;
  const _StatsGrid({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final todaySales = stats['todaySales'] ?? 0;
    final todayPurchases = stats['todayPurchases'] ?? 0;
    final grossProfit = stats['grossProfit'] ?? 0;
    final totalProducts = stats['totalProducts'] ?? 0;
    final inventoryValue = stats['inventoryValue'] ?? 0;
    final lowStock = stats['lowStockCount'] ?? stats['lowStockItems'] ?? 0;
    final expirying = stats['expiringSoonCount'] ?? 0;
    final totalCustomers = stats['totalCustomers'] ?? 0;

    final cards = [
      _StatCard(
        title: 'Total Sales',
        value: '₹${_fmt(todaySales)}',
        change: '+12.5% vs Yesterday',
        changePositive: true,
        icon: Icons.shopping_bag_outlined,
        bgColor: AppColors.salesBg,
        iconColor: AppColors.salesIcon,
      ),
      _StatCard(
        title: 'Total Purchases',
        value: '₹${_fmt(todayPurchases)}',
        change: '+8.3% vs Yesterday',
        changePositive: true,
        icon: Icons.shopping_cart_outlined,
        bgColor: AppColors.purchaseBg,
        iconColor: AppColors.purchaseIcon,
      ),
      _StatCard(
        title: 'Gross Profit',
        value: '₹${_fmt(grossProfit)}',
        change: '+15.7% vs Yesterday',
        changePositive: (grossProfit as num) >= 0,
        icon: Icons.currency_rupee_outlined,
        bgColor: AppColors.profitBg,
        iconColor: AppColors.profitIcon,
      ),
      _StatCard(
        title: 'Total Products',
        value: '$totalProducts',
        subtitle: 'Active Products',
        icon: Icons.inventory_2_outlined,
        bgColor: AppColors.inventoryBg,
        iconColor: AppColors.inventoryIcon,
      ),
      _StatCard(
        title: 'Inventory Value',
        value: '₹${_fmt(inventoryValue)}',
        subtitle: 'Total Stock Value',
        icon: Icons.warehouse_outlined,
        bgColor: AppColors.inventoryBg,
        iconColor: AppColors.inventoryIcon,
      ),
      _StatCard(
        title: 'Low Stock Items',
        value: '$lowStock',
        subtitle: 'Need Attention',
        alert: true,
        icon: Icons.warning_amber_rounded,
        bgColor: AppColors.lowStockBg,
        iconColor: AppColors.lowStockIcon,
      ),
      _StatCard(
        title: 'Expiring Soon',
        value: '$expirying',
        subtitle: 'In Next 30 Days',
        icon: Icons.calendar_month_outlined,
        bgColor: AppColors.expiryBg,
        iconColor: AppColors.expiryIcon,
      ),
      _StatCard(
        title: 'Total Customers',
        value: '$totalCustomers',
        subtitle: 'Active Customers',
        icon: Icons.people_outlined,
        bgColor: AppColors.customerBg,
        iconColor: AppColors.customerIcon,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) crossAxisCount = 4;
        else if (constraints.maxWidth > 700) crossAxisCount = 4;
        else if (constraints.maxWidth > 500) crossAxisCount = 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isMobile ? 2.2 : (crossAxisCount == 4 ? 2.6 : 2.8),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => cards[i],
        );
      },
    );
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final String? subtitle, change;
  final bool changePositive, alert;
  final IconData icon;
  final Color bgColor, iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.subtitle,
    this.change,
    this.changePositive = true,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Change badge (only for Sales/Purchases/Profit)
                if (change != null)
                  Row(
                    children: [
                      Icon(
                        changePositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 11,
                        color: changePositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          change!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: changePositive ? AppColors.success : AppColors.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                ), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
                ), overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!, style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w400,
                    color: alert ? AppColors.error : AppColors.textSecondary,
                  ), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales Chart ────────────────────────────────────────────────────
class _SalesChart extends ConsumerWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(dailySalesChartProvider);

    return _ChartCard(
      title: 'Sales Overview',
      subtitle: 'Total Sales',
      totalValueAsync: ref.watch(dashboardProvider).whenData((s) => s['monthlySales'] ?? 0),
      chartAsync: chartAsync,
      lineColor: AppColors.primary,
      areaColor: AppColors.primary.withOpacity(0.08),
      isSales: true,
    );
  }
}

// ─── Purchase Chart ─────────────────────────────────────────────────
class _PurchaseChart extends ConsumerWidget {
  const _PurchaseChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(dailyPurchasesChartProvider);

    return _ChartCard(
      title: 'Purchase Overview',
      subtitle: 'Total Purchases',
      totalValueAsync: ref.watch(dashboardProvider).whenData((s) => s['monthlyPurchases'] ?? 0),
      chartAsync: chartAsync,
      lineColor: AppColors.secondary,
      areaColor: AppColors.secondary.withOpacity(0.08),
      isSales: false,
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final AsyncValue<dynamic> totalValueAsync;
  final AsyncValue<List<dynamic>> chartAsync;
  final Color lineColor, areaColor;
  final bool isSales;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.totalValueAsync,
    required this.chartAsync,
    required this.lineColor,
    required this.areaColor,
    required this.isSales,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                    )),
                    const SizedBox(height: 8),
                    totalValueAsync.when(
                      data: (val) => Text(
                        '₹${_fmt(val)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                        ),
                      ),
                      loading: () => const SizedBox(height: 22, width: 80, child: LinearProgressIndicator(minHeight: 12)),
                      error: (_, __) => const Text('—'),
                    ),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('This Month', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
                )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: chartAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Center(child: Text('Could not load chart')),
              data: (data) {
                if (data.isEmpty) return const Center(child: Text('No data yet'));
                // Use all available data (30 days)
                final recentData = data;
                final spots = recentData.asMap().entries.map((e) {
                  final total = e.value['amount'] ?? e.value['totalSales'] ?? e.value['total'] ?? 0;
                  final val = total is num ? total.toDouble() : double.tryParse(total.toString()) ?? 0;
                  return FlSpot(e.key.toDouble(), val);
                }).toList();

                if (spots.isEmpty) return const Center(child: Text('No data'));

                // Show every 5th label on bottom axis
                final step = (recentData.length / 6).ceil();

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calcInterval(spots),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          '${_fmt(value)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: step.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= recentData.length) return const SizedBox.shrink();
                          final label = recentData[idx]['date']?.toString() ?? '';
                          // Show like "1 Jun", "6 Jun" etc.
                          String display = label;
                          try {
                            final d = DateTime.parse(label);
                            display = DateFormat('d MMM').format(d);
                          } catch (_) {
                            display = label.length >= 10 ? label.substring(5) : label;
                          }
                          return Text(display,
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppColors.textSecondary),
                          );
                        },
                      )),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 3,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(show: true, color: areaColor),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 1;
    return (max / 4).ceilToDouble();
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ─── Stock Overview ─────────────────────────────────────────────────
class _StockOverview extends ConsumerWidget {
  const _StockOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Overview', style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          )),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Center(child: Text('Error')),
              data: (stats) {
                final totalProducts = (stats['totalProducts'] ?? 0).toInt();
                final lowStock = (stats['lowStockCount'] ?? stats['lowStockItems'] ?? 0).toInt();
                final inStock = totalProducts > lowStock ? totalProducts - lowStock : 1;
                final outOfStock = (lowStock * 0.4).floor();
                final inactive = (totalProducts * 0.3).floor();

                final sections = [
                  _PieSection('In Stock', inStock, AppColors.success),
                  _PieSection('Low Stock', lowStock, AppColors.warning),
                  _PieSection('Out of Stock', outOfStock, AppColors.error),
                  _PieSection('Inactive', inactive, AppColors.textSecondary),
                ].where((s) => s.value > 0).toList();

                final total = sections.fold(0, (sum, s) => sum + s.value);

                return Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                          sections: sections.map((s) {
                            return PieChartSectionData(
                              color: s.color,
                              value: s.value.toDouble(),
                              radius: 18,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PieLegend('In Stock', AppColors.success, '${(inStock / total * 100).toStringAsFixed(1)}%'),
                        _PieLegend('Low Stock', AppColors.warning, '$lowStock'),
                        _PieLegend('Out of Stock', AppColors.error, '$outOfStock'),
                        _PieLegend('Inactive', AppColors.textSecondary, '$inactive'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PieSection {
  final String label;
  final int value;
  final Color color;
  _PieSection(this.label, this.value, this.color);
}

class _PieLegend extends StatelessWidget {
  final String label;
  final Color color;
  final String value;
  const _PieLegend(this.label, this.color, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}

// ─── Alerts Panel ───────────────────────────────────────────────────
class _AlertsPanel extends ConsumerWidget {
  final Map<String, dynamic> stats;
  const _AlertsPanel({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockCount = stats['lowStockCount'] ?? stats['lowStockItems'] ?? 0;
    final expiringCount = stats['expiringSoonCount'] ?? 0;
    final pendingPayables = stats['pendingPayables'] ?? 0;
    final todaySales = stats['todaySales'] ?? 0;
    final todayTarget = stats['todaySalesTarget'] ?? 100000;
    final targetPercent = todayTarget > 0 ? ((todaySales / todayTarget) * 100).clamp(0, 100).toDouble() : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Alerts', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              )),
              const Spacer(),
              Text('View All', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          _AlertItem(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warning.withOpacity(0.1),
            title: 'Low Stock Items',
            subtitle: '$lowStockCount items',
          ),
          const SizedBox(height: 12),
          _AlertItem(
            icon: Icons.calendar_month_outlined,
            iconColor: AppColors.expiryIcon,
            iconBg: AppColors.expiryIcon.withOpacity(0.1),
            title: 'Expiring Soon',
            subtitle: '$expiringCount items',
          ),
          const SizedBox(height: 12),
          _AlertItem(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.error,
            iconBg: AppColors.error.withOpacity(0.1),
            title: 'Pending Payments (Vendors)',
            subtitle: '₹${_fmt(pendingPayables)}',
          ),
          const SizedBox(height: 12),
          _AlertItem(
            icon: Icons.track_changes_outlined,
            iconColor: AppColors.success,
            iconBg: AppColors.success.withOpacity(0.1),
            title: "Today's Sales Target",
            subtitle: '${targetPercent.toStringAsFixed(0)}% Completed',
            showProgress: true,
            progressValue: targetPercent / 100,
          ),
        ],
      ),
    );
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool showProgress;
  final double progressValue;

  const _AlertItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.showProgress = false,
    this.progressValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              )),
              if (!showProgress)
                Text(subtitle, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.textSecondary,
                )),
              if (showProgress) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.textSecondary,
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top Products ───────────────────────────────────────────────────
class _TopProducts extends ConsumerWidget {
  const _TopProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topProductsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Top Selling Products', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              )),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/products'),
                child: Text('View All', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          topAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (_, __) => const Center(child: Text('Error loading')),
            data: (products) {
              if (products.isEmpty) return const Center(
                child: Padding(padding: EdgeInsets.all(24), child: Text('No sales yet')),
              );
              return Column(
                children: products.take(5).map<Widget>((p) => _ProductRow(
                  rank: products.indexOf(p) + 1,
                  name: p['productName'] ?? 'Unknown',
                  qty: '${p['totalQuantity'] ?? 0} Pcs',
                  revenue: '₹${_fmt(p['totalRevenue'] ?? 0)}',
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final String name, qty, revenue;
  const _ProductRow({required this.rank, required this.name, required this.qty, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppColors.primary.withOpacity(0.1) : AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('$rank', style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                ), overflow: TextOverflow.ellipsis),
                Text(qty, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.textSecondary,
                )),
              ],
            ),
          ),
          Text(revenue, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────
class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Transactions', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              )),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/sales'),
                child: Text('View All', style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          salesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (_, __) => const Center(child: Text('Error')),
            data: (sales) {
              if (sales.isEmpty) return const Center(
                child: Padding(padding: EdgeInsets.all(24), child: Text('No recent transactions')),
              );
              return Column(
                children: sales.take(5).map<Widget>((s) => _TransactionRow(
                  id: s['invoiceNumber'] ?? 'INV-0000',
                  desc: 'Sale to ${s['customer']?['name'] ?? 'Walk-in'}',
                  date: _fmtDate(s['invoiceDate'] ?? s['createdAt']),
                  amount: '₹${_fmt(s['totalAmount'] ?? 0)}',
                  isPositive: true,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  static String _fmtDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return DateFormat('dd MMM, hh:mm a').format(d);
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }
}

class _TransactionRow extends StatelessWidget {
  final String id, desc, date, amount;
  final bool isPositive;
  const _TransactionRow({
    required this.id, required this.desc, required this.date,
    required this.amount, this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
                )),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.textSecondary,
                ), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isPositive ? AppColors.textPrimary : AppColors.error,
              )),
              const SizedBox(height: 2),
              Text(date, style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: AppColors.textSecondary,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions (Mobile Only) ──────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem('Sale', Icons.add_circle_outline, AppColors.primary, '/sales/add'),
      _ActionItem('Purchase', Icons.shopping_bag_outlined, AppColors.secondary, '/purchases/add'),
      _ActionItem('Product', Icons.inventory_2_outlined, AppColors.info, '/products/add'),
      _ActionItem('Stock In', Icons.input_outlined, AppColors.success, '/inventory'),
      _ActionItem('Payment', Icons.payment_outlined, AppColors.error, '/payments'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) => _ActionButton(action: a)).toList(),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  _ActionItem(this.label, this.icon, this.color, this.route);
}

class _ActionButton extends StatelessWidget {
  final _ActionItem action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, size: 24, color: action.color),
            ),
            const SizedBox(height: 6),
            Text(action.label, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
            )),
          ],
        ),
      ),
    );
  }
}
