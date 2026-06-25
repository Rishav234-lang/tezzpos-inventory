import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Providers ──────────────────────────────────────────────────────

final _inventoryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.inventoryStats);
  return response.data as Map<String, dynamic>;
});

final _categoryListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.categories);
  final data = response.data as Map<String, dynamic>;
  return (data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
});

final _productListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.products, queryParams: params);
  return response.data as Map<String, dynamic>;
});

// ─── Screen ─────────────────────────────────────────────────────────

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _page = 1;
  int _limit = 10;
  String? _selectedCategoryId;
  String? _selectedStatus;

  Timer? _debounce;
  late Map<String, String> _currentParams;

  @override
  void initState() {
    super.initState();
    _updateParams();
  }

  void _updateParams() {
    _currentParams = {
      'page': '$_page',
      'limit': '$_limit',
      if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId!,
      if (_selectedStatus != null) 'status': _selectedStatus!,
    };
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = value;
        _page = 1;
        _updateParams();
      });
    });
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).delete('${ApiConstants.products}/$id');
      ref.invalidate(_productListProvider(_currentParams));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final statsAsync = ref.watch(_inventoryStatsProvider);
    final productsAsync = ref.watch(_productListProvider(_currentParams));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: isWide ? null : _buildMobileAppBar(),
      body: Column(
        children: [
          // Stats cards
          if (isWide)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _DesktopStatsCards(statsAsync: statsAsync),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _MobileStatsCards(statsAsync: statsAsync),
            ),

          // Search + Filters
          _buildSearchAndFilters(isWide),

          // Product list
          Expanded(
            child: productsAsync.when(
              loading: () => const AppLoading(),
              error: (err, _) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.invalidate(_productListProvider(_currentParams)),
              ),
              data: (result) {
                final products = result['data'] as List<dynamic>;
                final pagination = result['pagination'] as Map<String, dynamic>?;

                if (products.isEmpty) {
                  return AppEmptyState(
                    message: _searchQuery.isNotEmpty ? 'No products match "$_searchQuery"' : 'No products yet',
                    icon: Icons.shopping_bag_outlined,
                    actionLabel: 'Add Product',
                    onAction: () => context.push('/products/add'),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: isWide
                          ? _DesktopProductTable(
                              products: products,
                              onEdit: (id) => context.push('/products/$id/edit'),
                              onDelete: _deleteProduct,
                            )
                          : _MobileProductList(
                              products: products,
                              onEdit: (id) => context.push('/products/$id/edit'),
                              onDelete: _deleteProduct,
                            ),
                    ),
                    if (pagination != null && (pagination['totalPages'] ?? 1) > 1)
                      _PaginationBar(
                        page: _page,
                        totalPages: pagination['totalPages'] ?? 1,
                        total: pagination['total'] ?? 0,
                        onPageChanged: (p) => setState(() { _page = p; _updateParams(); }),
                        limit: _limit,
                        onLimitChanged: (l) => setState(() { _limit = l; _page = 1; _updateParams(); }),
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

  AppBar _buildMobileAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.bg,
      title: Text('Products', style: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      )),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primary),
          onPressed: () => context.push('/products/add'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isWide) {
    final categoriesAsync = ref.watch(_categoryListProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: isWide ? 16 : 8),
      child: Column(
        children: [
          // Search row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search by name, SKU or barcode...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                            onPressed: () { _searchController.clear(); _onSearchChanged(''); },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
                    onPressed: () {},
                    tooltip: 'Filters',
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                categoriesAsync.when(
                data: (categories) => _FilterDropdown(
                  label: _selectedCategoryId == null
                      ? 'All Categories'
                      : categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {'name': 'All Categories'})['name'] as String? ?? 'All Categories',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...categories.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String? ?? ''),
                    )),
                  ],
                  value: _selectedCategoryId,
                  onChanged: (v) => setState(() { _selectedCategoryId = v; _page = 1; _updateParams(); }),
                ),
                loading: () => const SizedBox(width: 120, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                error: (_, __) => _FilterDropdown(
                  label: 'All Categories',
                  items: const [DropdownMenuItem(value: null, child: Text('All Categories'))],
                  value: null,
                  onChanged: (v) {},
                ),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: _selectedStatus ?? 'Status: Active',
                items: const [
                  DropdownMenuItem(value: null, child: Text('Status: Active')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                ],
                value: _selectedStatus,
                onChanged: (v) => setState(() { _selectedStatus = v; _page = 1; _updateParams(); }),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Cards ──────────────────────────────────────────────────

class _DesktopStatsCards extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> statsAsync;
  const _DesktopStatsCards({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Row(
        children: [
          Expanded(child: _StatCardSkeleton()),
          SizedBox(width: 16),
          Expanded(child: _StatCardSkeleton()),
          SizedBox(width: 16),
          Expanded(child: _StatCardSkeleton()),
          SizedBox(width: 16),
          Expanded(child: _StatCardSkeleton()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final fmt = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
        return Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.inventory_2_outlined,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Total Products',
              value: '${stats['totalProducts'] ?? 0}',
              subtitle: 'Active Products',
              subtitleColor: AppColors.textSecondary,
            )),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(
              icon: Icons.notifications_active_outlined,
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFF59E0B),
              title: 'Low Stock',
              value: '${stats['lowStockCount'] ?? 0}',
              subtitle: 'Need Attention',
              subtitleColor: const Color(0xFFF97316),
            )),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(
              icon: Icons.cancel_outlined,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFEF4444),
              title: 'Out of Stock',
              value: '${stats['outOfStockCount'] ?? 0}',
              subtitle: 'Not Available',
              subtitleColor: const Color(0xFFEF4444),
            )),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF10B981),
              title: 'Total Value',
              value: fmt.format(stats['inventoryValue'] ?? 0),
              subtitle: 'Inventory Value',
              subtitleColor: AppColors.textSecondary,
            )),
          ],
        );
      },
    );
  }
}

class _MobileStatsCards extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> statsAsync;
  const _MobileStatsCards({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
        children: const [
          _StatCardSkeleton(),
          _StatCardSkeleton(),
          _StatCardSkeleton(),
          _StatCardSkeleton(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final fmt = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              icon: Icons.inventory_2_outlined,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Total Products',
              value: '${stats['totalProducts'] ?? 0}',
              subtitle: 'Active',
              subtitleColor: AppColors.textSecondary,
            ),
            _StatCard(
              icon: Icons.notifications_active_outlined,
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFF59E0B),
              title: 'Low Stock',
              value: '${stats['lowStockCount'] ?? 0}',
              subtitle: 'Need Attention',
              subtitleColor: const Color(0xFFF97316),
            ),
            _StatCard(
              icon: Icons.cancel_outlined,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFEF4444),
              title: 'Out of Stock',
              value: '${stats['outOfStockCount'] ?? 0}',
              subtitle: 'Not Available',
              subtitleColor: const Color(0xFFEF4444),
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF10B981),
              title: 'Total Value',
              value: fmt.format(stats['inventoryValue'] ?? 0),
              subtitle: 'Inventory Value',
              subtitleColor: AppColors.textSecondary,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: subtitleColor)),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
          const Spacer(),
          Container(width: 60, height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(width: 80, height: 18, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

// ─── Filter Dropdown ────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final List<DropdownMenuItem<String?>> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: items,
          hint: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        ),
      ),
    );
  }
}

// ─── Desktop Product Table ──────────────────────────────────────────

class _DesktopProductTable extends StatelessWidget {
  final List<dynamic> products;
  final ValueChanged<String> onEdit;
  final void Function(String id, String name) onDelete;

  const _DesktopProductTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _HeaderCell('Product', flex: 3),
                _HeaderCell('SKU / Barcode', flex: 2),
                _HeaderCell('Category', flex: 2),
                _HeaderCell('Purchase Price', flex: 1),
                _HeaderCell('Selling Price', flex: 1),
                _HeaderCell('Stock', flex: 1),
                _HeaderCell('Status', flex: 1),
                _HeaderCell('Action', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final p = products[index];
                return _DesktopProductRow(
                  product: p,
                  onEdit: () => onEdit(p['id'] as String),
                  onDelete: () => onDelete(p['id'] as String, p['name'] as String? ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
      )),
    );
  }
}

class _DesktopProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesktopProductRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final sku = product['sku'] as String? ?? '';
    final barcode = product['barcode'] as String? ?? '';
    final skuBarcode = sku.isNotEmpty ? sku : barcode;
    final category = product['category'] is Map ? (product['category'] as Map)['name'] as String? : product['category'] as String?;
    final sellingPrice = product['sellingPrice'] ?? 0;
    final purchasePrice = product['purchasePrice'] ?? 0;
    final stock = product['totalStock'] ?? 0;
    final status = product['status'] ?? 'ACTIVE';
    final minStock = product['minStockLevel'] ?? 0;

    final isOutOfStock = stock == 0;
    final isLowStock = stock > 0 && stock <= minStock;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Product
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                      Text(skuBarcode, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // SKU / Barcode
          Expanded(
            flex: 2,
            child: Text(skuBarcode, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(category ?? '—', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Purchase Price
          Expanded(
            flex: 1,
            child: Text('₹${NumberFormat('#,##0.00').format(double.tryParse(purchasePrice.toString()) ?? 0)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          // Selling Price
          Expanded(
            flex: 1,
            child: Text('₹${NumberFormat('#,##0.00').format(double.tryParse(sellingPrice.toString()) ?? 0)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          // Stock
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$stock', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isOutOfStock ? const Color(0xFFEF4444) : isLowStock ? const Color(0xFFF97316) : const Color(0xFF10B981),
                )),
                Text('units', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: _StatusBadge(status: status),
          ),
          // Action
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Product List ──────────────────────────────────────────

class _MobileProductList extends StatelessWidget {
  final List<dynamic> products;
  final ValueChanged<String> onEdit;
  final void Function(String id, String name) onDelete;

  const _MobileProductList({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = products[index];
        return _MobileProductCard(
          product: p,
          onEdit: () => onEdit(p['id'] as String),
          onDelete: () => onDelete(p['id'] as String, p['name'] as String? ?? ''),
        );
      },
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final sku = product['sku'] as String? ?? '';
    final category = product['category'] is Map ? (product['category'] as Map)['name'] as String? : product['category'] as String?;
    final sellingPrice = product['sellingPrice'] ?? 0;
    final stock = product['totalStock'] ?? 0;
    final status = product['status'] ?? 'ACTIVE';
    final minStock = product['minStockLevel'] ?? 0;
    final unit = product['unit'] as String? ?? '';

    final isOutOfStock = stock == 0;
    final isLowStock = stock > 0 && stock <= minStock;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Avatar / icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('$category${unit.isNotEmpty ? ' • $unit' : ''}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('SKU: $sku', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Right side: price, stock, more
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${NumberFormat('#,##0.00').format(double.tryParse(sellingPrice.toString()) ?? 0)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$stock units',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isOutOfStock ? const Color(0xFFEF4444) : isLowStock ? const Color(0xFFF97316) : const Color(0xFF10B981),
                    )),
                  const SizedBox(width: 6),
                  _StatusBadge(status: status),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
          // More actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Edit', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text('Delete', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.red.shade400)),
              ])),
            ],
            onSelected: (value) {
              if (value == 'edit') onEdit();
              else if (value == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Shared Components ────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : status,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280)),
      ),
    );
  }
}

// ─── Pagination Bar ─────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPageChanged;
  final int limit;
  final ValueChanged<int> onLimitChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
    required this.limit,
    required this.onLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: isWide
          ? Row(
              children: [
                Text('Showing ${(page - 1) * limit + 1} to ${(page * limit).clamp(1, total)} of $total products',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                _buildPageNumbers(),
                const Spacer(),
                Row(
                  children: [
                    Text('Rows per page: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: limit,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textPrimary),
                        onChanged: (v) => v != null ? onLimitChanged(v) : null,
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                          DropdownMenuItem(value: 50, child: Text('50')),
                          DropdownMenuItem(value: 100, child: Text('100')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                ),
                _buildPageNumbers(),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
                ),
              ],
            ),
    );
  }

  Widget _buildPageNumbers() {
    final pages = <Widget>[];
    const maxVisible = 5;

    int startPage = max(1, page - (maxVisible ~/ 2));
    int endPage = startPage + maxVisible - 1;
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = max(1, endPage - maxVisible + 1);
    }

    if (startPage > 1) {
      pages.add(_PageButton(page: 1, isActive: page == 1, onTap: () => onPageChanged(1)));
      if (startPage > 2) pages.add(Text('...', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)));
    }

    for (int i = startPage; i <= endPage; i++) {
      pages.add(_PageButton(page: i, isActive: page == i, onTap: () => onPageChanged(i)));
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) pages.add(Text('...', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)));
      pages.add(_PageButton(page: totalPages, isActive: page == totalPages, onTap: () => onPageChanged(totalPages)));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: pages);
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageButton({required this.page, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$page', style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppColors.textPrimary,
        )),
      ),
    );
  }
}

