import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

import '../../../../core/constants/api_constants.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../../core/widgets/app_loading.dart';



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



final dailySalesChartProvider = FutureProvider<List<dynamic>>((ref) async {

  final api = ref.read(apiClientProvider);

  final response = await api.get(ApiConstants.dashboardDailySales);

  return response.data as List<dynamic>;

});



class DashboardScreen extends ConsumerWidget {

  const DashboardScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final dashboardAsync = ref.watch(dashboardProvider);



    return Scaffold(

      appBar: AppBar(

        title: const Text('Dashboard'),

        actions: [

          IconButton(

            icon: const Icon(Icons.refresh),

            onPressed: () {

              ref.invalidate(dashboardProvider);

              ref.invalidate(lowStockProvider);

              ref.invalidate(recentSalesProvider);

              ref.invalidate(dailySalesChartProvider);

            },

          ),

          const SizedBox(width: 8),

        ],

      ),

      body: dashboardAsync.when(

        loading: () => const AppLoading(message: 'Loading dashboard...'),

        error: (err, _) => AppErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(dashboardProvider)),

        data: (stats) => RefreshIndicator(

          onRefresh: () async {

            ref.invalidate(dashboardProvider);

            ref.invalidate(lowStockProvider);

            ref.invalidate(recentSalesProvider);

            ref.invalidate(dailySalesChartProvider);

          },

          child: LayoutBuilder(

            builder: (context, constraints) {

              final isWide = constraints.maxWidth > 900;

              return SingleChildScrollView(

                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    _StatsGrid(stats: stats),

                    const SizedBox(height: 24),

                    if (isWide)

                      Row(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Expanded(flex: 3, child: _DailySalesChart()),

                          const SizedBox(width: 16),

                          Expanded(flex: 2, child: _LowStockCard()),

                        ],

                      )

                    else ...[

                      _DailySalesChart(),

                      const SizedBox(height: 16),

                      _LowStockCard(),

                    ],

                    const SizedBox(height: 16),

                    _RecentSalesCard(),

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



// ─── Stats Grid ─────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {

  final Map<String, dynamic> stats;

  const _StatsGrid({required this.stats});



  @override

  Widget build(BuildContext context) {

    final cards = [

      _StatData('Total Products', '${stats['totalProducts'] ?? 0}', Icons.shopping_bag_outlined, AppColors.primary),

      _StatData('Total Vendors', '${stats['totalVendors'] ?? 0}', Icons.people_outlined, AppColors.secondary),

      _StatData('Total Customers', '${stats['totalCustomers'] ?? 0}', Icons.person_outlined, AppColors.info),

      _StatData('Inventory Value', '₹${_fmt(stats['inventoryValue'])}', Icons.inventory_2_outlined, AppColors.success),

      _StatData("Today's Sales", '₹${_fmt(stats['todaySales'])}', Icons.point_of_sale_outlined, AppColors.warning),

      _StatData('Monthly Sales', '₹${_fmt(stats['monthlySales'])}', Icons.trending_up_outlined, AppColors.primary),

      _StatData('Receivables', '₹${_fmt(stats['pendingReceivables'])}', Icons.account_balance_wallet_outlined, AppColors.error),

      _StatData('Payables', '₹${_fmt(stats['pendingPayables'])}', Icons.payment_outlined, AppColors.secondary),

    ];



    return LayoutBuilder(

      builder: (context, constraints) {

        int crossAxisCount = 2;

        if (constraints.maxWidth > 1200) crossAxisCount = 4;

        else if (constraints.maxWidth > 700) crossAxisCount = 4;

        else if (constraints.maxWidth > 500) crossAxisCount = 3;



        return GridView.builder(

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: crossAxisCount,

            childAspectRatio: crossAxisCount <= 2 ? 2.0 : 2.2,

            crossAxisSpacing: 10,

            mainAxisSpacing: 10,

          ),

          itemCount: cards.length,

          itemBuilder: (context, index) {

            final c = cards[index];

            return Card(

              child: Padding(

                padding: const EdgeInsets.all(14),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Container(

                      padding: const EdgeInsets.all(6),

                      decoration: BoxDecoration(color: c.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),

                      child: Icon(c.icon, size: 18, color: c.color),

                    ),

                    const SizedBox(height: 10),

                    Text(c.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),

                    const SizedBox(height: 2),

                    Text(c.title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),

                  ],

                ),

              ),

            );

          },

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



class _StatData {

  final String title, value;

  final IconData icon;

  final Color color;

  const _StatData(this.title, this.value, this.icon, this.color);

}



// ─── Daily Sales Chart ──────────────────────────────────────────────

class _DailySalesChart extends ConsumerWidget {

  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final chartAsync = ref.watch(dailySalesChartProvider);



    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Daily Sales (Last 7 Days)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),

            const SizedBox(height: 20),

            SizedBox(

              height: 220,

              child: chartAsync.when(

                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),

                error: (_, __) => const Center(child: Text('Could not load chart')),

                data: (data) {

                  if (data.isEmpty) return const Center(child: Text('No sales data yet'));

                  final spots = data.asMap().entries.map((e) {

                    final total = (e.value['totalSales'] ?? e.value['total'] ?? 0);

                    final val = total is num ? total.toDouble() : double.tryParse(total.toString()) ?? 0;

                    return FlSpot(e.key.toDouble(), val);

                  }).toList();



                  return LineChart(

                    LineChartData(

                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _calcInterval(spots)),

                      titlesData: FlTitlesData(

                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,

                          getTitlesWidget: (value, meta) => Text('₹${_StatsGrid._fmt(value)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),

                        )),

                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,

                          getTitlesWidget: (value, meta) {

                            final idx = value.toInt();

                            if (idx < 0 || idx >= data.length) return const SizedBox.shrink();

                            final label = data[idx]['date']?.toString() ?? '';

                            return Text(label.length >= 10 ? label.substring(5, 10) : label, style: const TextStyle(fontSize: 10, color: Colors.grey));

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

                          color: AppColors.primary,

                          barWidth: 2.5,

                          dotData: FlDotData(show: spots.length <= 10),

                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),

                        ),

                      ],

                    ),

                  );

                },

              ),

            ),

          ],

        ),

      ),

    );

  }



  double _calcInterval(List<FlSpot> spots) {

    if (spots.isEmpty) return 1;

    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    if (max <= 0) return 1;

    return (max / 4).ceilToDouble();

  }

}



// ─── Low Stock Card ─────────────────────────────────────────────────

class _LowStockCard extends ConsumerWidget {

  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final lowStockAsync = ref.watch(lowStockProvider);



    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),

                const SizedBox(width: 8),

                const Expanded(child: Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.w600))),

                TextButton(onPressed: () => context.go('/inventory'), child: const Text('View All', style: TextStyle(fontSize: 12))),

              ],

            ),

            const Divider(),

            lowStockAsync.when(

              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),

              error: (_, __) => const Padding(padding: EdgeInsets.all(8), child: Text('Error loading data')),

              data: (products) {

                if (products.isEmpty) {

                  return const Padding(

                    padding: EdgeInsets.all(16),

                    child: Center(child: Text('All products are well stocked!', style: TextStyle(color: Colors.grey))),

                  );

                }

                return Column(

                  children: products.take(6).map<Widget>((p) => Padding(

                    padding: const EdgeInsets.symmetric(vertical: 5),

                    child: Row(

                      children: [

                        Container(

                          width: 6, height: 6,

                          decoration: BoxDecoration(color: (p['stock'] ?? 0) == 0 ? AppColors.error : AppColors.warning, shape: BoxShape.circle),

                        ),

                        const SizedBox(width: 10),

                        Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),

                        Text('${p['stock'] ?? 0}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: (p['stock'] ?? 0) == 0 ? AppColors.error : AppColors.warning)),

                        Text(' / ${p['minStockLevel'] ?? 0}', style: const TextStyle(fontSize: 11, color: Colors.grey)),

                      ],

                    ),

                  )).toList(),

                );

              },

            ),

          ],

        ),

      ),

    );

  }

}



// ─── Recent Sales Card ──────────────────────────────────────────────

class _RecentSalesCard extends ConsumerWidget {

  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final salesAsync = ref.watch(recentSalesProvider);



    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primary),

                const SizedBox(width: 8),

                const Expanded(child: Text('Recent Sales', style: TextStyle(fontWeight: FontWeight.w600))),

                TextButton(onPressed: () => context.go('/sales'), child: const Text('View All', style: TextStyle(fontSize: 12))),

              ],

            ),

            const Divider(),

            salesAsync.when(

              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),

              error: (_, __) => const Padding(padding: EdgeInsets.all(8), child: Text('Error loading data')),

              data: (sales) {

                if (sales.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No recent sales', style: TextStyle(color: Colors.grey))));

                return Column(

                  children: sales.take(5).map<Widget>((s) => Padding(

                    padding: const EdgeInsets.symmetric(vertical: 6),

                    child: Row(

                      children: [

                        Expanded(flex: 2, child: Text(s['invoiceNumber'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),

                        Expanded(flex: 2, child: Text(s['customer']?['name'] ?? 'Walk-in', style: const TextStyle(fontSize: 13, color: Colors.grey))),

                        Expanded(child: Text(s['invoiceDate']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))),

                        Text('₹${s['totalAmount'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  )).toList(),

                );

              },

            ),

          ],

        ),

      ),

    );

  }

}

