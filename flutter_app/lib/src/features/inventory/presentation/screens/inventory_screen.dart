import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_providers.dart';
import '../../../product/domain/entities/inventory_stats.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _activeFilter = 'All';
  String? _selectedCategoryId;
  final int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String? get _stockFilter {
    if (_activeFilter == 'Low Stock') return 'LOW';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ProductFilter(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      stockFilter: _stockFilter,
      page: _currentPage,
    );
    final productsAsync = ref.watch(productsProvider(filter));
    final categoriesAsync = ref.watch(categoriesProvider(''));
    final statsAsync = ref.watch(inventoryStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inventoryStatsProvider);
            ref.invalidate(productsProvider(filter));
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(context),
                      const SizedBox(height: 16),
                      statsAsync.when(
                        data: (stats) => _buildSummaryCards(context, stats),
                        loading: () => _buildSummaryShimmer(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterChips(categoriesAsync),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              productsAsync.when(
                data: (products) {
                  final filtered = _applyLocalFilter(products);
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _InventoryProductCard(product: filtered[index]),
                      ),
                      childCount: filtered.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _ProductCardShimmer(),
                    ),
                    childCount: 6,
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.stockAdjustment),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Adjust Stock',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Product> _applyLocalFilter(List<Product> products) {
    if (_activeFilter == 'Expiring Soon') {
      final now = DateTime.now();
      final cutoff = now.add(const Duration(days: 30));
      return products.where((p) {
        if (p.firstExpiryDate == null) return false;
        return p.firstExpiryDate!.isAfter(now) &&
            p.firstExpiryDate!.isBefore(cutoff);
      }).toList();
    }
    return products;
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppRoutes.dashboard),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.onSurface,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 8),
        Text(
          'Stock',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _searchFocusNode.requestFocus(),
          icon: const Icon(Icons.search, color: AppColors.onSurface, size: 24),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: () => _showStockFilterSheet(context),
          icon: Icon(
            Icons.filter_list,
            color: _activeFilter != 'All'
                ? AppColors.primary
                : AppColors.onSurface,
            size: 24,
          ),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, InventoryStats stats) {
    final items = [
      _SummaryData(
        label: 'Items',
        value: '${stats.totalProducts}',
        sub: 'View all',
        icon: Icons.inventory_2_outlined,
        iconBg: AppColors.primaryContainer,
        iconColor: AppColors.primary,
        onTap: () => setState(() {
          _activeFilter = 'All';
          _selectedCategoryId = null;
        }),
      ),
      _SummaryData(
        label: 'Stock value',
        value: '₹ ${_fmtL(stats.inventoryValue)}',
        sub: 'View details',
        icon: Icons.account_balance_wallet_outlined,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF388E3C),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total inventory value: ₹ ${_fmtL(stats.inventoryValue)}',
            ),
          ),
        ),
      ),
      _SummaryData(
        label: 'Low stock',
        value: '${stats.lowStockCount}',
        sub: 'View all',
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        onTap: () => setState(() => _activeFilter = 'Low Stock'),
      ),
      _SummaryData(
        label: 'Expiring soon',
        value: '${stats.expiringSoonCount}',
        sub: 'View all',
        icon: Icons.timer_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFD32F2F),
        onTap: () => setState(() => _activeFilter = 'Expiring Soon'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _SummaryCard(data: items[i]),
    );
  }

  String _fmtL(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildSummaryShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showStockFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Filter stock',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final label in ['All', 'Low Stock', 'Expiring Soon'])
                ListTile(
                  title: Text(label),
                  trailing: _activeFilter == label
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _activeFilter = label;
                      _selectedCategoryId = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (_) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(
          const Duration(milliseconds: 300),
          () => setState(() {}),
        );
      },
      decoration: InputDecoration(
        hintText: 'Search item stock...',
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: const Icon(Icons.qr_code_scanner, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AsyncValue<List<Category>> categoriesAsync) {
    final statusChips = ['All', 'Low Stock', 'Expiring Soon'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock status',
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: statusChips.map((label) {
                final isSelected =
                    _activeFilter == label && _selectedCategoryId == null;
                return _filterChip(
                  label: label,
                  selected: isSelected,
                  onTap: () => setState(() {
                    _activeFilter = label;
                    _selectedCategoryId = null;
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Categories',
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (cats) {
              if (cats.isEmpty) {
                return Text(
                  'No categories created yet',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              }
              return SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(
                      label: 'All categories',
                      selected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    ...cats.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      return _filterChip(
                        label: category.name,
                        selected: isSelected,
                        onTap: () => setState(() {
                          _selectedCategoryId = isSelected ? null : category.id;
                          _activeFilter = 'All';
                        }),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 38,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Text(
              'Could not load categories',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.onSurface,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.55),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilters =
        _activeFilter != 'All' ||
        _selectedCategoryId != null ||
        _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.filter_list_off : Icons.inventory_2_outlined,
                color: AppColors.primary.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No Matching Products' : 'No Products Yet',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing your filters or search term.'
                  : 'Products will appear here once added.',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _activeFilter = 'All';
                  _selectedCategoryId = null;
                  _searchController.clear();
                }),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryData {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _SummaryData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, size: 18, color: data.iconColor),
            ),
            const Spacer(),
            Text(
              data.label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  data.sub,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 13,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _InventoryProductCard extends StatelessWidget {
  final Product product;

  const _InventoryProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currency = NumberFormat('#,##,##0.00');

    final stockValue = product.stockValue;

    Color statusFg;
    Color statusBg;
    String statusText;
    Color qtyColor;

    if (product.isOutOfStock) {
      statusText = 'Out of stock';
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFC62828);
      qtyColor = const Color(0xFFC62828);
    } else if (product.isLowStock) {
      statusText = 'Low stock';
      statusBg = const Color(0xFFFFF3E0);
      statusFg = const Color(0xFFE65100);
      qtyColor = const Color(0xFFE65100);
    } else {
      final expiringDays = product.firstExpiryDate
          ?.difference(DateTime.now())
          .inDays;
      if (expiringDays != null && expiringDays <= 30 && expiringDays >= 0) {
        statusText = 'Expiring soon';
        statusBg = const Color(0xFFFFEBEE);
        statusFg = const Color(0xFFC62828);
        qtyColor = const Color(0xFF388E3C);
      } else {
        statusText = 'In stock';
        statusBg = const Color(0xFFE8F5E9);
        statusFg = const Color(0xFF2E7D32);
        qtyColor = const Color(0xFF388E3C);
      }
    }

    String expiryLabel() {
      if (product.firstExpiryDate == null) return 'N/A';
      final diff = product.firstExpiryDate!.difference(DateTime.now()).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      return dateFormat.format(product.firstExpiryDate!);
    }

    Color expiryColor() {
      if (product.firstExpiryDate == null) return AppColors.onSurfaceVariant;
      final diff = product.firstExpiryDate!.difference(DateTime.now()).inDays;
      if (diff <= 7) return AppColors.error;
      if (diff <= 30) return const Color(0xFFE65100);
      return AppColors.onSurface;
    }

    return InkWell(
      onTap: () => context.push('${AppRoutes.inventoryDetail}/${product.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: image + name + status + arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    image:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              product.imageUrl!.startsWith('http')
                                  ? product.imageUrl!
                                  : '${ApiConstants.baseUrl}${product.imageUrl!}',
                            ),
                            fit: BoxFit.contain,
                            onError: (_, _) {},
                          )
                        : null,
                  ),
                  child: product.imageUrl == null || product.imageUrl!.isEmpty
                      ? Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'SKU: ${product.sku ?? 'N/A'}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (product.barcode != null) ...[
                            Text(
                              '  •  ',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Barcode: ${product.barcode}',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusFg,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: statusFg,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Stock metrics row
            Row(
              children: [
                _MetricCol(
                  label: 'Quantity',
                  value: '${product.totalStock} pcs',
                  valueColor: qtyColor,
                ),
                _MetricCol(
                  label: 'Batch',
                  value: product.firstBatchNumber ?? 'N/A',
                ),
                _MetricCol(
                  label: 'Expiry',
                  value: expiryLabel(),
                  valueColor: expiryColor(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetricCol(
                  label: 'Purchase Price',
                  value: '₹ ${currency.format(product.costPrice)}',
                ),
                _MetricCol(
                  label: 'MRP',
                  value: product.firstMrp != null
                      ? '₹ ${currency.format(product.firstMrp)}'
                      : 'N/A',
                ),
                _MetricCol(
                  label: 'Stock Value',
                  value: '₹ ${currency.format(stockValue)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricCol({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCardShimmer extends StatelessWidget {
  const _ProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
