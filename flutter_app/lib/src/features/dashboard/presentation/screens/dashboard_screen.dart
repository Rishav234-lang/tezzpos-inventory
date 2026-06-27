import 'package:flutter/material.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();

  Future<void> _refresh() async {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(recentSalesProvider);
    ref.invalidate(recentPurchasesProvider);
    ref.invalidate(topSellingProductsProvider);
    await ref.read(dashboardStatsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull?.user;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentSalesAsync = ref.watch(recentSalesProvider);
    final recentPurchasesAsync = ref.watch(recentPurchasesProvider);
    final topProductsAsync = ref.watch(topSellingProductsProvider);

    return Scaffold(
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
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _StatsGrid(stats: stats),
                loading: () => const _StatsGridShimmer(),
                error: (_, _) => const _StatsGrid(
                  stats: DashboardStats(
                    totalProducts: 0, totalVendors: 0, totalCustomers: 0,
                    inventoryValue: 0, todaySales: 0, todaySalesCount: 0,
                    monthlySales: 0, monthlySalesCount: 0, todayPurchases: 0,
                    monthlyPurchases: 0, grossProfit: 0, pendingReceivables: 0,
                    pendingPayables: 0, expiringSoonCount: 0, lowStockCount: 0,
                    todaySalesTarget: 0,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, 'Recent Transactions'),
            ),
            SliverToBoxAdapter(
              child: _buildRecentTransactions(context, recentSalesAsync, recentPurchasesAsync),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, 'Top Selling Products'),
            ),
            SliverToBoxAdapter(
              child: _buildTopProducts(context, topProductsAsync),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildCenterFab(context),
    );
  }
  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  String _getGreeting() {
    // IST is UTC+5:30
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
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
    }
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TezzPOS',
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Retail',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go(AppRoutes.chooseRole);
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      "Here's what's happening in your store today.",
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 16),
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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
            onTap: () {},
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
        child: _EmptyCard(message: 'Error: ${salesAsync.error ?? purchasesAsync.error}'),
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
        children: transactions.map((t) => _TransactionTile(transaction: t)).toList(),
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, AsyncValue<List<TopSellingProduct>> asyncValue) {
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
        children: products.take(3).map((p) => _TopProductTile(product: p)).toList(),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 64,
      child: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Add', style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _DrawerAction(icon: Icons.add_shopping_cart, label: 'Add Sale', color: AppColors.primary, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.shopping_basket, label: 'Add Purchase', color: AppColors.secondary, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.add_box, label: 'Add Product', color: AppColors.success, onTap: () {
              context.pop();
              context.push(AppRoutes.addProduct);
            }),
            _DrawerAction(icon: Icons.download, label: 'Stock In', color: AppColors.info, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.upload, label: 'Stock Out', color: AppColors.warning, onTap: () => _comingSoon(context)),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: 'Dashboard', index: 0, selectedIndex: _selectedNavIndex, onTap: (i) => setState(() => _selectedNavIndex = i)),
          _NavItem(icon: Icons.inventory_2, label: 'Products', index: 1, selectedIndex: _selectedNavIndex, onTap: (i) {
            setState(() => _selectedNavIndex = i);
            context.push(AppRoutes.products);
          }),
          const SizedBox(width: 48), // space for FAB
          _NavItem(icon: Icons.bar_chart, label: 'Sales', index: 2, selectedIndex: _selectedNavIndex, onTap: (i) => setState(() => _selectedNavIndex = i)),
          _NavItem(icon: Icons.more_horiz, label: 'More', index: 3, selectedIndex: _selectedNavIndex, onTap: (i) {
            _scaffoldKey.currentState?.openDrawer();
            setState(() => _selectedNavIndex = i);
          }),
        ],
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
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _initials(user?.name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(user?.email ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerAction(icon: Icons.category, label: 'Categories', color: AppColors.primary, onTap: () => context.push(AppRoutes.categories)),
            _DrawerAction(icon: Icons.inventory_2, label: 'Products', color: AppColors.success, onTap: () => context.push(AppRoutes.products)),
            _DrawerAction(icon: Icons.local_shipping, label: 'Vendors', color: AppColors.info, onTap: () => context.push(AppRoutes.vendors)),
            const Divider(),
            _DrawerAction(icon: Icons.add_shopping_cart, label: 'Add Sale', color: AppColors.primary, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.shopping_basket, label: 'Add Purchase', color: AppColors.secondary, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.download, label: 'Stock In', color: AppColors.info, onTap: () => _comingSoon(context)),
            _DrawerAction(icon: Icons.upload, label: 'Stock Out', color: AppColors.warning, onTap: () => _comingSoon(context)),
            const Divider(),
            _DrawerAction(icon: Icons.logout, label: 'Logout', color: AppColors.error, onTap: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go(AppRoutes.chooseRole);
            }),
          ],
        ),
      ),
    );
  }
}
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  String formatCurrency(double value) {
    return '₹ ${NumberFormat("#,##,###").format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        title: 'Total Sales',
        value: formatCurrency(stats.monthlySales),
        icon: Icons.currency_rupee,
        bgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
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
        iconColor: const Color(0xFF00838F),
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
          color: isAlert ? iconColor.withValues(alpha: 0.2) : AppColors.outline.withValues(alpha: 0.5),
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
                '₹ ${NumberFormat("#,##,###").format(transaction.totalAmount)}',
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
            '₹ ${NumberFormat("#,##,###").format(product.totalRevenue)}',
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

  const _NavItem({required this.icon, required this.label, required this.index, required this.selectedIndex, required this.onTap});

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
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
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

  const _DrawerAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
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
