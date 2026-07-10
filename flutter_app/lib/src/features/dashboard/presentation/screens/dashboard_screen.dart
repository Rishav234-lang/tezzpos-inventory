import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../providers/dashboard_providers.dart';
import '../../../purchase/presentation/providers/purchase_providers.dart';
import '../../../sale/presentation/providers/sale_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool detailed;

  const DashboardScreen({super.key, this.detailed = false});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();

  Future<void> _refresh() async {
    final filter = _dashboardFilter();
    ref.invalidate(dashboardStatsProvider(filter));
    ref.invalidate(recentSalesProvider(filter));
    ref.invalidate(recentPurchasesProvider(filter));
    ref.invalidate(topSellingProductsProvider(filter));
    await ref.read(dashboardStatsProvider(filter).future);
  }

  Future<bool> _showExitConfirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Exit app?'),
              content: const Text('Do you want to close TezzPOS now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _exitApp() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.fuchsia) {
      SystemNavigator.pop();
    }
  }

  void _openTodaySales() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    ref.read(saleFilterProvider.notifier).state = SaleFilter(
      startDate: start,
      endDate: end,
    );
    context.push(AppRoutes.salesHistory);
  }

  void _openTodayPurchases() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    ref.read(purchaseFilterProvider.notifier).state = PurchaseFilter(
      startDate: DateFormat('yyyy-MM-dd').format(start),
      endDate: DateFormat('yyyy-MM-dd').format(end),
    );
    context.push(AppRoutes.purchases);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull?.user;
    final filter = _dashboardFilter();
    final statsAsync = ref.watch(dashboardStatsProvider(filter));
    final recentSalesAsync = ref.watch(recentSalesProvider(filter));
    final recentPurchasesAsync = ref.watch(recentPurchasesProvider(filter));
    final topProductsAsync = ref.watch(topSellingProductsProvider(filter));

    final body = !widget.detailed
        ? _buildSimpleDashboard(
            context,
            ref,
            user?.name ?? 'Owner',
            statsAsync,
          )
        : Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            drawer: _buildDrawer(context, ref),
            body: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, ref, user?.name ?? 'Owner'),
                  ),
                  SliverToBoxAdapter(child: _buildSimpleFlowPreview(context)),
                  SliverToBoxAdapter(
                    child: statsAsync.when(
                      data: (stats) => _StatsGrid(stats: stats),
                      loading: () => const _StatsGridShimmer(),
                      error: (_, __) => const _StatsGrid(
                        stats: DashboardStats(
                          totalProducts: 0,
                          totalVendors: 0,
                          totalCustomers: 0,
                          inventoryValue: 0,
                          todaySales: 0,
                          todaySalesCount: 0,
                          monthlySales: 0,
                          monthlySalesCount: 0,
                          todayPurchases: 0,
                          monthlyPurchases: 0,
                          grossProfit: 0,
                          pendingReceivables: 0,
                          pendingPayables: 0,
                          expiringSoonCount: 0,
                          lowStockCount: 0,
                          todaySalesTarget: 0,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(
                      context,
                      'Recent Transactions',
                      route: AppRoutes.salesHistory,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecentTransactions(
                      context,
                      recentSalesAsync,
                      recentPurchasesAsync,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(
                      context,
                      'Top Selling Products',
                      route: AppRoutes.products,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTopProducts(context, topProductsAsync),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(context, ref),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirm(context);
        if (shouldExit) _exitApp();
      },
      child: body,
    );
  }

  String _initials(String? name, {String? fallback}) {
    final source = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (fallback != null && fallback.trim().isNotEmpty)
        ? fallback.trim()
        : '';
    if (source.isEmpty) return 'U';
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _getGreeting() {
    // IST is UTC+5:30
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      final filter = _dashboardFilter();
      ref.invalidate(dashboardStatsProvider(filter));
      ref.invalidate(recentSalesProvider(filter));
      ref.invalidate(recentPurchasesProvider(filter));
      ref.invalidate(topSellingProductsProvider(filter));
    }
  }

  DashboardDateFilter _dashboardFilter() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));
    return DashboardDateFilter(startDate: start, endDate: end);
  }

  Widget _buildSimpleDashboard(
    BuildContext context,
    WidgetRef ref,
    String userName,
    AsyncValue<DashboardStats> statsAsync,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, ref),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context, ref, userName, showDateFilter: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: statsAsync.when(
        data: (stats) => _SimpleTodaySummary(
          stats: stats,
          onSalesTap: _openTodaySales,
          onPurchasesTap: _openTodayPurchases,
        ),
                loading: () => const _SimpleSummaryLoading(),
                error: (_, __) => const _SimpleSummaryError(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MainWorkPanel(
                onPurchase: () =>
                    context.push('${AppRoutes.simpleFlow}?mode=purchase'),
                onSell: () => context.push('${AppRoutes.simpleFlow}?mode=sell'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _SimpleManagePanel(
                onProducts: () => context.push(AppRoutes.products),
                onStock: () => context.push(AppRoutes.inventory),
                onCustomers: () => context.push(AppRoutes.customers),
                onCategories: () => context.push(AppRoutes.categories),
                onSuppliers: () => context.push(AppRoutes.vendors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.detailedDashboard),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Detailed Dashboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String userName, {
    bool showDateFilter = true,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TezzPOS',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Retail',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 11,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.profile),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _initials(
                          userName,
                          fallback: ref
                              .watch(authNotifierProvider)
                              .valueOrNull
                              ?.user
                              ?.companyName,
                        ),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, $userName',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showDateFilter
                            ? "Detailed view for selected day."
                            : "Ready for purchase and sell.",
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDateFilter)
                  GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: context.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    String? route,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: route != null ? () => context.push(route) : null,
            child: Text(
              'View All',
              style: context.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFlowPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(AppRoutes.simpleFlow),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Quick Inventory',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buy stock, sell items, and check alerts from one guided screen.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<RecentTransaction>> salesAsync,
    AsyncValue<List<RecentTransaction>> purchasesAsync,
  ) {
    final isLoading = salesAsync.isLoading || purchasesAsync.isLoading;
    if (isLoading) return const _RecentTransactionsShimmer();

    if (salesAsync.hasError || purchasesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          message: 'Error: ${salesAsync.error ?? purchasesAsync.error}',
        ),
      );
    }

    final sales = salesAsync.valueOrNull ?? [];
    final purchases = purchasesAsync.valueOrNull ?? [];
    final allTransactions = [...sales, ...purchases]
      ..sort((a, b) => b.date.compareTo(a.date));
    final transactions = allTransactions.take(5).toList();

    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(message: 'No recent transactions'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: transactions
            .map((t) => _TransactionTile(transaction: t))
            .toList(),
      ),
    );
  }

  Widget _buildTopProducts(
    BuildContext context,
    AsyncValue<List<TopSellingProduct>> asyncValue,
  ) {
    if (asyncValue.isLoading) return const _TopProductsShimmer();

    if (asyncValue.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(message: 'Error: ${asyncValue.error}'),
      );
    }

    final products = asyncValue.valueOrNull ?? [];
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(message: 'No sales data yet'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: products
            .take(3)
            .map((p) => _TopProductTile(product: p))
            .toList(),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Dashboard',
                index: 0,
                selectedIndex: _selectedNavIndex,
                onTap: (i) => setState(() => _selectedNavIndex = i),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'Customers',
                index: 1,
                selectedIndex: _selectedNavIndex,
                onTap: (i) {
                  setState(() => _selectedNavIndex = i);
                  context.push(AppRoutes.customers);
                },
              ),
              _NavItem(
                icon: Icons.warehouse_outlined,
                label: 'Stock',
                index: 2,
                selectedIndex: _selectedNavIndex,
                onTap: (i) {
                  setState(() => _selectedNavIndex = i);
                  context.push(AppRoutes.inventory);
                },
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                index: 3,
                selectedIndex: _selectedNavIndex,
                onTap: (i) {
                  setState(() => _selectedNavIndex = i);
                  context.push(AppRoutes.products);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _initials(user?.name, fallback: user?.companyName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerAction(
              icon: Icons.route,
              label: 'Purchase / Sell',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.simpleFlow),
            ),
            const Divider(),
            _DrawerAction(
              icon: Icons.inventory_2,
              label: 'Products',
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.products),
            ),
            _DrawerAction(
              icon: Icons.warehouse_outlined,
              label: 'Stock',
              color: AppColors.warning,
              onTap: () => context.push(AppRoutes.inventory),
            ),
            _DrawerAction(
              icon: Icons.people,
              label: 'Customers',
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.customers),
            ),
            _DrawerAction(
              icon: Icons.category,
              label: 'Categories',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.categories),
            ),
            _DrawerAction(
              icon: Icons.local_shipping,
              label: 'Suppliers',
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.vendors),
            ),
            const Divider(),
            _DrawerAction(
              icon: Icons.analytics_outlined,
              label: 'Detailed Dashboard',
              color: AppColors.warning,
              onTap: () => context.push(AppRoutes.detailedDashboard),
            ),
            const Divider(),
            _DrawerAction(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.error,
              onTap: () {
                ref.read(authNotifierProvider.notifier).logout();
                context.go(AppRoutes.chooseRole);
              },
            ),
            _DrawerAction(
              icon: Icons.power_settings_new,
              label: 'Exit App',
              color: AppColors.error,
              onTap: () async {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                }
                final shouldExit = await _showExitConfirm(context);
                if (shouldExit) _exitApp();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleTodaySummary extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback onSalesTap;
  final VoidCallback onPurchasesTap;

  const _SimpleTodaySummary({
    required this.stats,
    required this.onSalesTap,
    required this.onPurchasesTap,
  });

  String _money(double value) => 'Rs ${NumberFormat("#,##,##0").format(value)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: context.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SimpleMetric(
                  label: 'Sales',
                  value: _money(stats.todaySales),
                  color: AppColors.primary,
                  icon: Icons.point_of_sale,
                  onTap: onSalesTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SimpleMetric(
                  label: 'Purchases',
                  value: _money(stats.todayPurchases),
                  color: AppColors.success,
                  icon: Icons.add_shopping_cart,
                  onTap: onPurchasesTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SimpleMetric(
                  label: 'Low stock',
                  value: '${stats.lowStockCount}',
                  color: AppColors.warning,
                  icon: Icons.warning_amber_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SimpleMetric(
                  label: 'Customers',
                  value: '${stats.totalCustomers}',
                  color: AppColors.info,
                  icon: Icons.people_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SimpleMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const Spacer(),
                    if (tappable)
                      Icon(
                        Icons.chevron_right,
                        color: color.withValues(alpha: 0.8),
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (tappable) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tap to open',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleSummaryLoading extends StatelessWidget {
  const _SimpleSummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SimpleSummaryError extends StatelessWidget {
  const _SimpleSummaryError();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(message: 'Today data not available');
  }
}

class _MainWorkPanel extends StatelessWidget {
  final VoidCallback onPurchase;
  final VoidCallback onSell;

  const _MainWorkPanel({required this.onPurchase, required this.onSell});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Work',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use these two buttons for most shop work.',
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SimpleActionButton(
                title: 'Purchase',
                subtitle: 'Add stock',
                icon: Icons.add_shopping_cart,
                color: AppColors.success,
                onTap: onPurchase,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SimpleActionButton(
                title: 'Sell',
                subtitle: 'Reduce stock',
                icon: Icons.point_of_sale,
                color: AppColors.primary,
                onTap: onSell,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SimpleActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SimpleActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleManagePanel extends StatelessWidget {
  final VoidCallback onProducts;
  final VoidCallback onStock;
  final VoidCallback onCustomers;
  final VoidCallback onCategories;
  final VoidCallback onSuppliers;

  const _SimpleManagePanel({
    required this.onProducts,
    required this.onStock,
    required this.onCustomers,
    required this.onCategories,
    required this.onSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Follow these steps to manage the shop in order.',
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ManageTile(
            label: 'Stock',
            icon: Icons.warehouse_outlined,
            color: AppColors.warning,
            onTap: onStock,
            step: null,
            fullWidth: true,
            subtitle: 'Open stock list and current quantity',
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.95,
            children: [
              _ManageTile(
                step: 1,
                label: 'Categories',
                icon: Icons.category_outlined,
                color: AppColors.primary,
                onTap: onCategories,
                subtitle: 'Create groups first',
              ),
              _ManageTile(
                step: 2,
                label: 'Products',
                icon: Icons.inventory_2_outlined,
                color: AppColors.success,
                onTap: onProducts,
                subtitle: 'Add items under groups',
              ),
              _ManageTile(
                step: 3,
                label: 'Suppliers',
                icon: Icons.local_shipping_outlined,
                color: AppColors.warning,
                onTap: onSuppliers,
                subtitle: 'Vendor details',
              ),
              _ManageTile(
                step: 4,
                label: 'Customers',
                icon: Icons.people_outline,
                color: AppColors.info,
                onTap: onCustomers,
                subtitle: 'Buyer details',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? step;
  final String? subtitle;
  final bool fullWidth;

  const _ManageTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.step,
    this.subtitle,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              if (step != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  String formatCurrency(double value) {
    return '₹ ${NumberFormat("#,##,##0").format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        title: 'Total Sales',
        value: formatCurrency(stats.monthlySales),
        icon: Icons.currency_rupee,
        bgColor: AppColors.primaryContainer,
        iconColor: AppColors.primary,
      ),
      _StatItem(
        title: 'Total Purchases',
        value: formatCurrency(stats.monthlyPurchases),
        icon: Icons.shopping_bag,
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
      ),
      _StatItem(
        title: 'Gross Profit',
        value: formatCurrency(stats.grossProfit),
        icon: Icons.trending_up,
        bgColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFEF6C00),
      ),
      _StatItem(
        title: 'Inventory Value',
        value: formatCurrency(stats.inventoryValue),
        icon: Icons.inventory_2,
        bgColor: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF6A1B9A),
      ),
      _StatItem(
        title: 'Total Customers',
        value: '${stats.totalCustomers}',
        icon: Icons.people,
        bgColor: const Color(0xFFFFFDE7),
        iconColor: const Color(0xFFF9A825),
      ),
      _StatItem(
        title: 'Total Suppliers',
        value: '${stats.totalVendors}',
        icon: Icons.local_shipping,
        bgColor: const Color(0xFFE0F7FA),
        iconColor: AppColors.info,
      ),
      _StatItem(
        title: 'Low Stock Items',
        value: '${stats.lowStockCount}',
        icon: Icons.warning_amber,
        bgColor: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFC62828),
        isAlert: true,
      ),
      _StatItem(
        title: 'Expiring Soon',
        value: '${stats.expiringSoonCount}',
        icon: Icons.date_range,
        bgColor: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFFF8F00),
        isAlert: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index]
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isAlert;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert
              ? iconColor.withValues(alpha: 0.2)
              : AppColors.outline.withValues(alpha: 0.5),
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isAlert ? iconColor : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final RecentTransaction transaction;

  const _TransactionTile({required this.transaction});

  Color get _typeColor {
    switch (transaction.type) {
      case 'SALE':
        return AppColors.success;
      case 'PURCHASE':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (transaction.type) {
      case 'SALE':
        return Icons.arrow_downward;
      case 'PURCHASE':
        return Icons.shopping_cart;
      default:
        return Icons.payment;
    }
  }

  String get _name {
    return transaction.customerName ?? transaction.vendorName ?? 'Walk-in';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.invoiceNumber,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.type == 'SALE' ? 'Sale to' : 'Purchase from'} $_name',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${NumberFormat("#,##,##0").format(transaction.totalAmount)}',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _typeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('hh:mm a').format(transaction.date),
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final TopSellingProduct product;

  const _TopProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.totalQuantity} Pcs',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat("#,##,##0").format(product.totalRevenue)}',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          message,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: List.generate(8, (_) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _RecentTransactionsShimmer extends StatelessWidget {
  const _RecentTransactionsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(4, (_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TopProductsShimmer extends StatelessWidget {
  const _TopProductsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(3, (_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }),
        ),
      ),
    );
  }
}
